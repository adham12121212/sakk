import 'package:dartz/dartz.dart';

import '../../../../core/data/online_repo.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/network_info.dart';
import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/installment_payment.dart';
import '../../domain/entities/installment_plan.dart';
import '../../domain/entities/installment_plan_draft.dart';
import '../../domain/entities/scheduled_payment.dart';
import '../../domain/installment_repo/installment_repo.dart';
import '../installment_data_source/installment_data_source.dart';
import '../installment_data_source/installment_local_data_source.dart';
import '../models/installment_plan_model.dart';

class InstallmentRepoImpl with OnlineRepo implements InstallmentRepo {
  final InstallmentDataSource _dataSource;
  final InstallmentLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  final AppLogger _logger;
  InstallmentRepoImpl(
    this._dataSource,
    this._localDataSource,
    this._networkInfo,
    this._logger,
  );

  @override
  NetworkInfo get networkInfo => _networkInfo;
  @override
  AppLogger get logger => _logger;

  /// Applies [change] to the cached list (if any), so a change made online
  /// is also reflected the next time the app is offline.
  Future<void> _updateCache(
    List<InstallmentPlanModel> Function(List<InstallmentPlanModel> current)
    change,
  ) async {
    try {
      final current = await _localDataSource.getCachedPlans();
      if (current == null) return;
      await _localDataSource.cachePlans(change(current));
    } catch (e) {
      _logger.warning(
        'Updating the offline installments cache failed',
        data: {'error': '$e'},
      );
    }
  }

  @override
  Future<Either<Failure, List<InstallmentPlan>>> getPlans() {
    return loadWithCache<InstallmentPlan, InstallmentPlanModel>(
      operation: 'getInstallmentPlans',
      load: _dataSource.getPlans,
      save: _localDataSource.cachePlans,
      cached: _localDataSource.getCachedPlans,
    );
  }

  @override
  Future<Either<Failure, InstallmentPlan>> savePlan({
    String? id,
    required InstallmentPlanDraft draft,
    required List<ScheduledPayment> unpaid,
  }) {
    return online('saveInstallmentPlan', () async {
      final saved = await _dataSource.savePlan(
        InstallmentPlanModel.writeJson(draft, id: id),
        InstallmentPlanModel.paymentsJson(unpaid),
      );
      await _updateCache(
        (current) => id == null
            ? [saved, ...current]
            : [for (final p in current) p.id == id ? saved : p],
      );
      return saved;
    });
  }

  @override
  Future<Either<Failure, void>> deletePlan(String id) {
    return online('deleteInstallmentPlan', () async {
      await _dataSource.deletePlan(id);
      await _updateCache(
        (current) => current.where((p) => p.id != id).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, InstallmentPayment>> setPaymentPaid(
    String paymentId, {
    DateTime? paidAt,
  }) {
    return online('setInstallmentPaymentPaid', () async {
      final saved = await _dataSource.setPaymentPaid(paymentId, paidAt);
      await _updateCache(
        (current) => [
          for (final p in current)
            p.id == saved.planId ? p.withPayment(saved) : p,
        ],
      );
      return saved;
    });
  }

  @override
  Future<void> clearCachedInstallments() async {
    try {
      await _localDataSource.clearAll();
    } catch (e) {
      _logger.warning(
        'Clearing the offline installments cache failed',
        data: {'error': '$e'},
      );
    }
  }
}
