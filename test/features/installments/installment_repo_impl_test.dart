import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/exceptions.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/core/error/network_info.dart';
import 'package:sakk/core/logger/app_logger.dart';
import 'package:sakk/features/installments/data/installment_data_source/installment_data_source.dart';
import 'package:sakk/features/installments/data/installment_data_source/installment_local_data_source.dart';
import 'package:sakk/features/installments/data/installment_repo_impl/installment_repo_impl.dart';
import 'package:sakk/features/installments/data/models/installment_payment_model.dart';
import 'package:sakk/features/installments/data/models/installment_plan_model.dart';
import 'package:sakk/features/installments/domain/entities/scanned_installment.dart';
import 'package:sakk/features/installments/domain/entities/scheduled_payment.dart';

import 'installment_models_test.dart' show planRow;

class _FakeNetwork implements NetworkInfo {
  bool connected = true;
  @override
  Future<bool> get isConnected async => connected;
  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

class _SilentLogger implements AppLogger {
  @override
  void debug(String message, {Map<String, dynamic>? data}) {}
  @override
  void info(String message, {Map<String, dynamic>? data}) {}
  @override
  void warning(String message, {Map<String, dynamic>? data}) {}
  @override
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {}
}

class _FakeRemote implements InstallmentDataSource {
  List<InstallmentPlanModel> rows = [];
  bool fail = false;
  Map<String, dynamic>? lastPlan;
  List<Map<String, dynamic>>? lastPayments;

  @override
  Future<List<InstallmentPlanModel>> getPlans() async {
    if (fail) throw ServerException('boom');
    return rows;
  }

  @override
  Future<InstallmentPlanModel> savePlan(Map<String, dynamic> planJson, List<Map<String, dynamic>> paymentsJson) async {
    if (fail) throw ServerException('boom');
    lastPlan = planJson;
    lastPayments = paymentsJson;
    return InstallmentPlanModel.fromJson({...planRow(id: planJson['id'] as String? ?? 'new'), 'title': planJson['title']});
  }

  @override
  Future<void> deletePlan(String id) async {}

  ScannedInstallment scan = const ScannedInstallment(title: 'TV');
  @override
  Future<ScannedInstallment> extractInstallment({String? imagePath, String? pdfText, String? text}) async {
    if (fail) throw ServerException('boom');
    return scan;
  }

  @override
  Future<InstallmentPaymentModel> setPaymentPaid(String paymentId, DateTime? paidAt) async =>
      InstallmentPaymentModel(id: paymentId, planId: 'pl1', dueDate: DateTime(2026, 12, 31), amount: 2000, paidAt: paidAt);
}

class _MemoryCache implements InstallmentLocalDataSource {
  List<InstallmentPlanModel>? plans;
  @override
  Future<List<InstallmentPlanModel>?> getCachedPlans() async => plans;
  @override
  Future<void> cachePlans(List<InstallmentPlanModel> p) async => plans = p;
  @override
  Future<void> clearAll() async => plans = null;
}

void main() {
  late _FakeRemote remote;
  late _MemoryCache cache;
  late _FakeNetwork network;
  late InstallmentRepoImpl repo;

  setUp(() {
    remote = _FakeRemote();
    cache = _MemoryCache();
    network = _FakeNetwork();
    repo = InstallmentRepoImpl(remote, cache, network, _SilentLogger());
  });

  test('a successful load is saved for offline use', () async {
    remote.rows = [InstallmentPlanModel.fromJson(planRow())];
    final result = await repo.getPlans();
    expect(result.getOrElse(() => []).single.id, 'pl1');
    expect(cache.plans!.single.id, 'pl1');
  });

  test('offline, serves the saved list; without one, says no connection', () async {
    network.connected = false;
    final noCache = await repo.getPlans();
    expect(noCache.fold((f) => f, (_) => null), const NetworkFailure(NetworkFailure.noConnectionMessage));
    cache.plans = [InstallmentPlanModel.fromJson(planRow())];
    final cached = await repo.getPlans();
    expect(cached.getOrElse(() => []).single.id, 'pl1');
  });

  test('saving sends the plan and its unpaid installments, and updates the cache', () async {
    cache.plans = [InstallmentPlanModel.fromJson(planRow())];
    final plan = InstallmentPlanModel.fromJson(planRow());
    final result = await repo.savePlan(
      id: 'pl1',
      draft: plan.toDraft(),
      unpaid: [ScheduledPayment(dueDate: DateTime(2027, 1, 31), amount: 2000)],
    );
    expect(result.isRight(), isTrue);
    expect(remote.lastPlan!['id'], 'pl1');
    expect(remote.lastPayments, [{'due_date': '2027-01-31', 'amount': 2000.0}]);
    expect(cache.plans, hasLength(1));

    await repo.savePlan(draft: plan.toDraft(), unpaid: const []);
    expect(cache.plans!.map((p) => p.id), ['new', 'pl1']);
  });

  test('marking a payment paid updates it in the cached plan', () async {
    cache.plans = [InstallmentPlanModel.fromJson(planRow())];
    await repo.setPaymentPaid('py2', paidAt: DateTime(2026, 12, 30));
    expect(cache.plans!.single.isCompleted, isTrue);
    await repo.setPaymentPaid('py2');
    expect(cache.plans!.single.isCompleted, isFalse);
  });

  test('writes need a connection and report server errors', () async {
    network.connected = false;
    final offline = await repo.deletePlan('pl1');
    expect(offline.fold((f) => f, (_) => null), const NetworkFailure(NetworkFailure.noConnectionMessage));
    network.connected = true;
    remote.fail = true;
    final failed = await repo.savePlan(draft: InstallmentPlanModel.fromJson(planRow()).toDraft(), unpaid: const []);
    expect(failed.fold((f) => f, (_) => null), isA<ServerFailure>());
  });

  test('deleting removes the plan from the cache', () async {
    cache.plans = [InstallmentPlanModel.fromJson(planRow())];
    await repo.deletePlan('pl1');
    expect(cache.plans, isEmpty);
  });
}
