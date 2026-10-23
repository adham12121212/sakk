import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/user_facing_error.dart';
import 'package:sakk/features/pro/data/purchases_gateway.dart';
import 'package:sakk/features/pro/domain/entities/pro_status.dart';
import 'package:sakk/features/pro/domain/pro_limit.dart';
import 'package:sakk/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// get_usage_status's answer for a free user near the limits.
Map<String, dynamic> freeJson() => {
  'pro': false,
  'day': '2026-10-18',
  'plan': null,
  'scan': {'used': 1, 'limit': 3, 'remaining': 2},
  'chat': {'used': 5, 'limit': 5, 'remaining': 0},
  'items': {
    'products': {'count': 5, 'limit': 5},
    'subscriptions': {'count': 1, 'limit': 3},
    'installments': {'count': 0, 'limit': 1},
  },
};

void main() {
  group('ProStatus.fromJson', () {
    test('free user: counters and item limits', () {
      final s = ProStatus.fromJson(freeJson());
      expect(s.isPro, isFalse);
      expect(s.plan, PlanKind.free);
      expect(s.scan.remaining, 2);
      expect(s.scan.isUsedUp, isFalse);
      expect(s.chat.isUsedUp, isTrue);
      expect(s.item(LimitedItem.products).isFull, isTrue);
      expect(s.item(LimitedItem.subscriptions).isFull, isFalse);
    });

    test('pro: unlimited is null, never full or used up', () {
      final s = ProStatus.fromJson({
        'pro': true,
        'plan': {
          'product_id': 'sakk_pro:yearly',
          'is_trial': false,
          'active_until': '2027-10-18T10:00:00Z',
          'will_renew': true,
          'billing_issue': false,
        },
        'scan': {'used': 40, 'limit': null, 'remaining': null},
        'chat': {'used': 3, 'limit': 200, 'remaining': 197},
        'items': {
          'products': {'count': 80, 'limit': null},
        },
      });
      expect(s.plan, PlanKind.yearly);
      expect(s.scan.isUnlimited, isTrue);
      expect(s.scan.isUsedUp, isFalse);
      expect(s.item(LimitedItem.products).isFull, isFalse);
      expect(s.entitlement!.expiresAt!.isUtc, isFalse);
    });

    test('plan kinds: monthly, trial with days left, billing issue', () {
      ProStatus pro(Map<String, dynamic> plan) =>
          ProStatus.fromJson({'pro': true, 'plan': plan});
      expect(pro({'product_id': 'sakk_pro:monthly'}).plan, PlanKind.monthly);
      expect(pro({'product_id': 'sakk_pro_annual'}).plan, PlanKind.yearly);
      expect(
        pro({'product_id': 'sakk_pro:monthly', 'billing_issue': true}).plan,
        PlanKind.billingIssue,
      );

      final trial = pro({
        'product_id': 'sakk_pro:monthly',
        'is_trial': true,
        'active_until': '2026-10-23T12:00:00Z',
      });
      expect(trial.plan, PlanKind.trial);
      expect(trial.trialDaysLeft(DateTime.utc(2026, 10, 18, 12)), 5);
      expect(trial.trialDaysLeft(DateTime.utc(2026, 10, 23, 11)), 1);
      expect(trial.trialDaysLeft(DateTime.utc(2026, 10, 24)), 0);
    });

    test(
      'an expired Pro row reads as free, with the plan kept for the card',
      () {
        final s = ProStatus.fromJson({
          'pro': false,
          'plan': {
            'product_id': 'sakk_pro:monthly',
            'active_until': '2026-01-01T00:00:00Z',
            'will_renew': false,
          },
        });
        expect(s.plan, PlanKind.free);
        expect(s.entitlement?.productId, 'sakk_pro:monthly');
      },
    );
  });

  test('a store purchase unlocks at once: limits lifted, counts kept', () {
    final free = ProStatus.fromJson(freeJson());
    final unlocked = free.withStoreEntitlement(
      const ProEntitlement(
        isActive: true,
        productId: 'sakk_pro:monthly',
        isTrial: true,
      ),
    );
    expect(unlocked.isPro, isTrue);
    expect(unlocked.plan, PlanKind.trial);
    expect(unlocked.item(LimitedItem.products).count, 5);
    expect(unlocked.item(LimitedItem.products).isFull, isFalse);
    expect(unlocked.scan.isUsedUp, isFalse);

    // An inactive store entitlement never downgrades: the server decides.
    expect(
      free.withStoreEntitlement(const ProEntitlement(isActive: false)),
      free,
    );
  });

  group('ProLimit', () {
    test(
      'database LIMIT_REACHED becomes a code and opens the paywall',
      () async {
        final events = <PaywallReason>[];
        final sub = ProLimit.events.listen(events.add);
        addTearDown(sub.cancel);

        final code = ProLimit.codeFor(
          const PostgrestException(
            message: 'LIMIT_REACHED:products',
            code: 'P0001',
          ),
        );
        expect(code, 'limit_reached:products');
        expect(ProLimit.kindOf(code), 'products');

        // Also when another error wraps it in its text.
        expect(
          ProLimit.codeFor(Exception('Failed: LIMIT_REACHED:installments')),
          'limit_reached:installments',
        );

        await Future<void>.delayed(Duration.zero);
        expect(events, [
          PaywallReason.productsLimit,
          PaywallReason.installmentsLimit,
        ]);
      },
    );

    test(
      "the AI functions' 402: free opens the paywall, Pro's fair-use cap doesn't",
      () async {
        final events = <PaywallReason>[];
        final sub = ProLimit.events.listen(events.add);
        addTearDown(sub.cancel);

        final free = ProLimit.codeFor(
          const FunctionException(
            status: 402,
            details: {'code': 'LIMIT_REACHED', 'type': 'chat', 'pro': false},
          ),
        );
        final pro = ProLimit.codeFor(
          const FunctionException(
            status: 402,
            details: {'code': 'LIMIT_REACHED', 'type': 'chat', 'pro': true},
          ),
        );
        expect(free, 'limit_reached:chat');
        expect(pro, 'limit_reached:fair_use');
        expect(ProLimit.codeFor(const FunctionException(status: 500)), isNull);
        expect(ProLimit.codeFor(Exception('nothing to see')), isNull);

        await Future<void>.delayed(Duration.zero);
        expect(events, [PaywallReason.chatLimit]);
      },
    );

    test('limit codes get their own messages', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
      expect(
        userFacingError(l10n, 'limit_reached:products'),
        l10n.limitReachedProducts,
      );
      expect(
        userFacingError(l10n, 'limit_reached:scan'),
        l10n.limitReachedScan,
      );
      expect(
        userFacingError(l10n, 'limit_reached:fair_use'),
        l10n.limitReachedFairUse,
      );
    });
  });

  group('ProOffer.yearlySavingsPercent', () {
    ProPackage pkg(
      double price, {
      bool yearly = false,
      String currency = 'EGP',
    }) => ProPackage(
      id: yearly ? 'y' : 'm',
      isYearly: yearly,
      price: price,
      priceString: '$price',
      currencyCode: currency,
    );

    test('29/month vs 249/year saves ~28%', () {
      expect(
        ProOffer(
          monthly: pkg(29),
          yearly: pkg(249, yearly: true),
        ).yearlySavingsPercent,
        28,
      );
    });

    test(
      'nothing when it isn\'t cheaper, a plan is missing, or currencies differ',
      () {
        expect(
          ProOffer(
            monthly: pkg(20),
            yearly: pkg(240, yearly: true),
          ).yearlySavingsPercent,
          isNull,
        );
        expect(
          ProOffer(yearly: pkg(249, yearly: true)).yearlySavingsPercent,
          isNull,
        );
        expect(
          ProOffer(
            monthly: pkg(29),
            yearly: pkg(10, yearly: true, currency: 'USD'),
          ).yearlySavingsPercent,
          isNull,
        );
      },
    );
  });
}
