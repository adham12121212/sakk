import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/service/receipt_ai_client.dart';
import '../../../../core/util/pii_masker.dart';
import '../../domain/entities/billing_cycle.dart';
import '../../domain/entities/scanned_subscription.dart';
import '../../domain/entities/subscription_category.dart';
import '../models/catalog_service_model.dart';
import '../models/user_subscription_model.dart';
import '../../../pro/domain/pro_limit.dart';

abstract class SubscriptionDataSource {
  Future<List<CatalogServiceModel>> getCatalog();

  Future<List<UserSubscriptionModel>> getSubscriptions();

  Future<UserSubscriptionModel> addSubscription(
    Map<String, dynamic> insertJson,
  );

  Future<UserSubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updateJson,
  );

  Future<void> deleteSubscription(String id);

  Future<void> updateRenewalDate(String id, DateTime nextRenewalDate);

  Future<ScannedSubscription> extractSubscription({
    String? imagePath,
    String? text,
    List<String> knownServices,
  });
}

class SubscriptionDataSourceImpl implements SubscriptionDataSource {
  final SupabaseClient _client;
  final ReceiptAiClient _ai;
  SubscriptionDataSourceImpl(this._client, {ReceiptAiClient? ai})
    : _ai = ai ?? ReceiptAiClient(_client);

  /// Error code passed up as the failure message when the AI found no
  /// subscription in the screenshot or text (see userFacingError).
  static const unreadableSubscription = 'unreadable_subscription';

  /// The screenshot is only needed while the AI reads it.
  static const _screenshotUrlExpiry = Duration(minutes: 10);

  static const _catalogTable = 'subscription_catalog';
  static const _table = 'user_subscriptions';

  @override
  Future<List<CatalogServiceModel>> getCatalog() async {
    try {
      // RLS lets users read inactive services too (so their subscriptions
      // keep a name and logo); only active ones are offered to pick.
      final rows = await _client
          .from(_catalogTable)
          .select()
          .eq('is_active', true)
          .order('name');
      return (rows as List)
          .map(
            (row) => CatalogServiceModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to load the subscription catalog: $e');
    }
  }

  @override
  Future<List<UserSubscriptionModel>> getSubscriptions() async {
    try {
      final rows = await _client
          .from(_table)
          .select(UserSubscriptionModel.selectColumns)
          .order('next_renewal_date');
      return (rows as List)
          .map(
            (row) =>
                UserSubscriptionModel.fromJson(row as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw ServerException('Failed to load subscriptions: $e');
    }
  }

  @override
  Future<UserSubscriptionModel> addSubscription(
    Map<String, dynamic> insertJson,
  ) async {
    try {
      final row = await _client
          .from(_table)
          .insert(insertJson)
          .select(UserSubscriptionModel.selectColumns)
          .single();
      ProLimit.notifyUsageChanged();
      return UserSubscriptionModel.fromJson(row);
    } catch (e) {
      throw ProLimit.exceptionFor(e, 'Failed to save subscription: $e');
    }
  }

  @override
  Future<UserSubscriptionModel> updateSubscription(
    String id,
    Map<String, dynamic> updateJson,
  ) async {
    try {
      final row = await _client
          .from(_table)
          .update(updateJson)
          .eq('id', id)
          .select(UserSubscriptionModel.selectColumns)
          .single();
      return UserSubscriptionModel.fromJson(row);
    } catch (e) {
      throw ServerException('Failed to update subscription: $e');
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
      ProLimit.notifyUsageChanged();
    } catch (e) {
      throw ServerException('Failed to delete subscription: $e');
    }
  }

  @override
  Future<void> updateRenewalDate(String id, DateTime nextRenewalDate) async {
    try {
      await _client
          .from(_table)
          .update({
            'next_renewal_date': nextRenewalDate
                .toIso8601String()
                .split('T')
                .first,
          })
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to update the renewal date: $e');
    }
  }

  @override
  Future<ScannedSubscription> extractSubscription({
    String? imagePath,
    String? text,
    List<String> knownServices = const [],
  }) async {
    UploadedReceipt? upload;
    try {
      if (imagePath != null) {
        upload = await _ai.upload(imagePath, expiry: _screenshotUrlExpiry);
      }
      // Full card numbers and email addresses never leave the device.
      final message = text == null
          ? null
          : PiiMasker.scrub(PiiMasker.maskCardNumbers(text));
      final data = await _ai.extract({
        'mode': 'subscription',
        'imageUrl': ?upload?.signedUrl,
        'text': ?message,
        'knownServices': knownServices,
      });
      return ScannedSubscription(
        serviceName: data['serviceName'] as String?,
        planName: data['planName'] as String?,
        price: (data['price'] as num?)?.toDouble(),
        currency: data['currency'] as String?,
        billingCycle: switch (data['billingCycle']) {
          'monthly' => BillingCycle.monthly,
          'yearly' => BillingCycle.yearly,
          _ => null,
        },
        nextRenewalDate: _date(data['nextRenewalDate']),
        chargeDate: _date(data['chargeDate']),
        paymentMethod: data['paymentMethod'] as String?,
        category: SubscriptionCategoryX.fromName(data['category'] as String?),
        confidence: (data['confidence'] as num?)?.toDouble() ?? 0,
      );
    } on ServerException catch (e) {
      if (e.message == ReceiptAiClient.unreadable) {
        throw ServerException(unreadableSubscription);
      }
      rethrow;
    } catch (e) {
      throw ServerException('Subscription scan failed: $e');
    } finally {
      // Not kept: subscriptions don't store the screenshot.
      if (upload != null) await _ai.delete(upload.path);
    }
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
