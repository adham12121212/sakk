import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/exceptions.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/error/user_facing_error.dart';
import 'package:sakk/core/service/receipt_ai_client.dart';
import 'package:sakk/core/util/pii_masker.dart';
import 'package:sakk/features/subscriptions/data/subscription_data_source/subscription_data_source.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/catalog_service.dart';
import 'package:sakk/features/subscriptions/domain/entities/scanned_subscription.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:sakk/features/subscriptions/domain/smart_add_match.dart';
import 'package:sakk/features/subscriptions/domain/usecase/extract_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/smart_add_cubit.dart';
import 'package:sakk/l10n/app_localizations_en.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const netflix = CatalogService(
  id: 'n',
  name: 'Netflix',
  category: SubscriptionCategory.streaming,
  plans: [
    CatalogPlan(
      name: 'Basic',
      price: 120,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
    ),
    CatalogPlan(
      name: 'Standard',
      price: 190,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
    ),
    CatalogPlan(
      name: 'Premium',
      price: 240,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
    ),
  ],
);
const youtube = CatalogService(id: 'y', name: 'YouTube Premium');
const we = CatalogService(id: 'w', name: 'WE');
const shahid = CatalogService(
  id: 's',
  name: 'Shahid',
  plans: [
    CatalogPlan(
      name: 'VIP',
      price: 100,
      currency: 'EGP',
      billingCycle: BillingCycle.monthly,
    ),
    CatalogPlan(
      name: 'VIP',
      price: 1000,
      currency: 'EGP',
      billingCycle: BillingCycle.yearly,
    ),
  ],
);
const catalog = [netflix, youtube, we, shahid];

/// Records what the data source asks of the AI pipeline.
class FakeAi implements ReceiptAiClient {
  Map<String, dynamic>? sentBody;
  final deleted = <String>[];
  Map<String, dynamic> answer = {
    'serviceName': 'Netflix',
    'price': 240,
    'currency': 'EGP',
  };
  Object? throwOnExtract;

  @override
  Future<UploadedReceipt> upload(
    String imagePath, {
    required Duration expiry,
  }) async => const UploadedReceipt(
    path: 'u1/1.jpg',
    signedUrl: 'https://signed/u1/1.jpg',
  );

  @override
  Future<Map<String, dynamic>> extract(Map<String, dynamic> body) async {
    sentBody = body;
    if (throwOnExtract != null) throw throwOnExtract!;
    return answer;
  }

  @override
  Future<void> delete(String path) async => deleted.add(path);
}

void main() {
  group('PiiMasker.maskCardNumbers', () {
    test('shortens full card numbers to the last 4 digits', () {
      expect(
        PiiMasker.maskCardNumbers('Card 4111 1111 1111 4242 charged'),
        'Card •• 4242 charged',
      );
      expect(
        PiiMasker.maskCardNumbers('بطاقة 5555-5555-5555-4444'),
        'بطاقة •• 4444',
      );
      expect(PiiMasker.maskCardNumbers('4111111111114242'), '•• 4242');
    });

    test('leaves amounts, dates, phones and masked cards alone', () {
      const sms =
          'تم خصم 12,500.00 جنيه في 2026-10-12 من بطاقتك المنتهية بـ 4242. للاستفسار 01012345678';
      expect(PiiMasker.maskCardNumbers(sms), sms);
      expect(
        PiiMasker.maskCardNumbers('EGP 1500 on **** 4242'),
        'EGP 1500 on **** 4242',
      );
    });
  });

  group('matchCatalogService', () {
    test('exact names, merchant descriptors and longer names', () {
      expect(matchCatalogService('Netflix', catalog), netflix);
      expect(matchCatalogService('NETFLIX.COM', catalog), netflix);
      expect(matchCatalogService('GOOGLE *YouTubePremium', catalog), youtube);
      expect(matchCatalogService('youtube premium family', catalog), youtube);
    });

    test('no match for unknown, too short or short-name lookalikes', () {
      expect(matchCatalogService('Gym membership', catalog), isNull);
      expect(matchCatalogService('Weekly paper', catalog), isNull); // not "WE"
      expect(matchCatalogService('WE', catalog), we); // exact still works
      expect(matchCatalogService('ab', catalog), isNull);
      expect(matchCatalogService(null, catalog), isNull);
    });
  });

  group('matchPlan', () {
    test('by plan name, else by price; ambiguous means no plan', () {
      expect(
        matchPlan(netflix, const ScannedSubscription(planName: 'premium')),
        netflix.plans[2],
      );
      expect(
        matchPlan(netflix, const ScannedSubscription(price: 190)),
        netflix.plans[1],
      );
      expect(
        matchPlan(
          netflix,
          const ScannedSubscription(price: 190, currency: 'USD'),
        ),
        isNull,
      );
      expect(matchPlan(netflix, const ScannedSubscription(price: 999)), isNull);
      // Two "VIP" plans: the cycle decides, or nothing does.
      expect(
        matchPlan(shahid, const ScannedSubscription(planName: 'VIP')),
        isNull,
      );
      expect(
        matchPlan(
          shahid,
          const ScannedSubscription(
            planName: 'VIP',
            billingCycle: BillingCycle.yearly,
          ),
        ),
        shahid.plans[1],
      );
    });
  });

  group('suggestedRenewal', () {
    final today = DateTime(2026, 10, 12);

    test('uses the shown renewal, rolled forward if it passed', () {
      expect(
        suggestedRenewal(
          ScannedSubscription(nextRenewalDate: DateTime(2026, 11, 3)),
          BillingCycle.monthly,
          today,
        ),
        DateTime(2026, 11, 3),
      );
      expect(
        suggestedRenewal(
          ScannedSubscription(nextRenewalDate: DateTime(2026, 10, 1)),
          BillingCycle.monthly,
          today,
        ),
        DateTime(2026, 11, 1),
      );
    });

    test('one cycle after a shown charge, else one cycle from today', () {
      expect(
        suggestedRenewal(
          ScannedSubscription(chargeDate: DateTime(2026, 10, 5)),
          BillingCycle.monthly,
          today,
        ),
        DateTime(2026, 11, 5),
      );
      expect(
        suggestedRenewal(
          ScannedSubscription(chargeDate: DateTime(2026, 3, 5)),
          BillingCycle.yearly,
          today,
        ),
        DateTime(2027, 3, 5),
      );
      expect(
        suggestedRenewal(
          const ScannedSubscription(),
          BillingCycle.monthly,
          today,
        ),
        DateTime(2026, 11, 12),
      );
    });
  });

  group('SubscriptionDataSourceImpl.extractSubscription', () {
    late FakeAi ai;
    late SubscriptionDataSourceImpl source;

    setUp(() {
      ai = FakeAi();
      source = SubscriptionDataSourceImpl(
        SupabaseClient('https://x.supabase.co', 'anon'),
        ai: ai,
      );
    });

    test('masks pasted text before it is sent and reads the answer', () async {
      ai.answer = {
        'serviceName': 'Netflix',
        'planName': 'Premium',
        'price': 240,
        'currency': 'EGP',
        'billingCycle': 'monthly',
        'nextRenewalDate': null,
        'chargeDate': '2026-10-05',
        'paymentMethod': 'Visa •• 4242',
        'category': 'streaming',
        'confidence': 0.9,
      };
      final scan = await source.extractSubscription(
        text:
            'Charged 240 EGP to 4111 1111 1111 4242 at NETFLIX.COM, receipt to me@mail.com',
        knownServices: ['Netflix'],
      );

      expect(ai.sentBody!['mode'], 'subscription');
      expect(
        ai.sentBody!['text'],
        'Charged 240 EGP to •• 4242 at NETFLIX.COM, receipt to [email]',
      );
      expect(ai.sentBody!.containsKey('imageUrl'), isFalse);
      expect(ai.sentBody!['knownServices'], ['Netflix']);

      expect(scan.serviceName, 'Netflix');
      expect(scan.billingCycle, BillingCycle.monthly);
      expect(scan.chargeDate, DateTime(2026, 10, 5));
      expect(scan.nextRenewalDate, isNull);
      expect(scan.category, SubscriptionCategory.streaming);
    });

    test(
      'a screenshot is uploaded, sent, and always deleted afterwards',
      () async {
        await source.extractSubscription(imagePath: '/tmp/shot.jpg');
        expect(ai.sentBody!['imageUrl'], 'https://signed/u1/1.jpg');
        expect(ai.deleted, ['u1/1.jpg']);

        ai.throwOnExtract = ServerException(ReceiptAiClient.unreadable);
        await expectLater(
          source.extractSubscription(imagePath: '/tmp/shot.jpg'),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              SubscriptionDataSourceImpl.unreadableSubscription,
            ),
          ),
        );
        expect(ai.deleted, ['u1/1.jpg', 'u1/1.jpg']);
      },
    );

    test('a busy AI keeps its own code', () async {
      ai.throwOnExtract = ServerException(ReceiptAiClient.aiBusy);
      await expectLater(
        source.extractSubscription(text: 'x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            ReceiptAiClient.aiBusy,
          ),
        ),
      );
    });
  });

  test('the unreadable code has its own message', () {
    final l10n = AppLocalizationsEn();
    expect(
      userFacingError(l10n, SubscriptionDataSourceImpl.unreadableSubscription),
      l10n.subscriptionScanUnreadable,
    );
    expect(userFacingError(l10n, ReceiptAiClient.aiBusy), l10n.scanBusy);
  });

  group('SmartAddCubit', () {
    test('matches the catalog and hands the form what it read', () async {
      final cubit = SmartAddCubit(
        _FakeExtract(
          const Right(
            ScannedSubscription(
              serviceName: 'NETFLIX.COM',
              price: 240,
              currency: 'EGP',
            ),
          ),
        ),
      );
      await cubit.read(text: 'sms', catalog: catalog);
      final state = cubit.state as SmartAddReady;
      expect(state.args.service, netflix);
      expect(state.args.plan, netflix.plans[2]);
      expect(state.args.scan!.price, 240);

      cubit.acknowledge();
      expect(cubit.state, isA<SmartAddIdle>());
    });

    test(
      'an unknown service opens the form as a custom one; failures are reported',
      () async {
        final custom = SmartAddCubit(
          _FakeExtract(
            const Right(ScannedSubscription(serviceName: 'Gold\'s Gym')),
          ),
        );
        await custom.read(text: 'sms', catalog: catalog);
        expect((custom.state as SmartAddReady).args.service, isNull);

        final failing = SmartAddCubit(
          _FakeExtract(
            const Left(
              ServerFailure(SubscriptionDataSourceImpl.unreadableSubscription),
            ),
          ),
        );
        await failing.read(text: 'sms', catalog: catalog);
        expect(
          (failing.state as SmartAddFailure).message,
          SubscriptionDataSourceImpl.unreadableSubscription,
        );
      },
    );

    test('sends the catalog names so the AI can use them', () async {
      final extract = _FakeExtract(const Right(ScannedSubscription()));
      await SmartAddCubit(extract).read(text: 'sms', catalog: catalog);
      expect(extract.knownServices, [
        'Netflix',
        'YouTube Premium',
        'WE',
        'Shahid',
      ]);
    });
  });
}

class _FakeExtract implements ExtractSubscriptionUseCase {
  _FakeExtract(this.result);
  final Either<Failure, ScannedSubscription> result;
  List<String>? knownServices;

  @override
  Future<Either<Failure, ScannedSubscription>> call({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  }) async {
    this.knownServices = knownServices;
    return result;
  }
}
