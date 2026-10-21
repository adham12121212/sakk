import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../data/pro_status_data_source.dart';
import '../../data/purchases_gateway.dart';
import '../../domain/entities/pro_status.dart';
import '../../domain/pro_limit.dart';

class ProState extends Equatable {
  const ProState({this.status = ProStatus.unknown, this.hasLoadedOnce = false, this.loadFailed = false});

  final ProStatus status;

  /// The server's status has been read at least once for this account.
  final bool hasLoadedOnce;

  /// The last read failed (offline, server down); what's shown is older or
  /// unknown. Screens offer a retry instead of loading forever.
  final bool loadFailed;

  bool get isPro => status.isPro;

  @override
  List<Object?> get props => [status, hasLoadedOnce, loadFailed];
}

/// The signed-in user's plan: Pro or free, today's AI use and item counts
/// against the limits. App-wide; the paywall, the plan badge, the counters
/// and the add buttons read it.
///
/// The server (get_usage_status) is the source of truth and enforces the
/// limits. The store's word (RevenueCat) is laid on top so Pro shows the
/// moment a purchase completes, before the webhook reaches the server.
///
/// Re-reads the server when the account changes, after a purchase or
/// restore, whenever [ProLimit.usageChanged] fires (a scan, a chat
/// message, an item added or deleted), and when the app comes back to the
/// foreground (a renewal, expiry or limit change made on the server).
class ProCubit extends Cubit<ProState> {
  ProCubit(
    this._dataSource,
    this._gateway, {
    required Stream<String?> userIdChanges,
    required AppLogger logger,
    Stream<void>? usageChanged,
    Stream<void> appResumed = const Stream.empty(),
    Duration refreshDebounce = const Duration(milliseconds: 400),
    Duration serverCatchUpInterval = const Duration(seconds: 2),
  })  : _logger = logger,
        _refreshDebounce = refreshDebounce,
        _serverCatchUpInterval = serverCatchUpInterval,
        super(const ProState()) {
    _subscriptions = [
      userIdChanges.distinct().listen(_onUserChanged),
      _gateway.entitlementChanges.listen(_applyStore),
      (usageChanged ?? ProLimit.usageChanged).listen((_) => _scheduleRefresh()),
      appResumed.listen((_) => _scheduleRefresh()),
    ];
  }

  final ProStatusDataSource _dataSource;
  final PurchasesGateway _gateway;
  final AppLogger _logger;
  final Duration _refreshDebounce;
  final Duration _serverCatchUpInterval;
  late final List<StreamSubscription<Object?>> _subscriptions;

  String? _userId;
  ProEntitlement? _store;
  Timer? _debounce;

  /// The last server read said Pro (not only the store).
  bool _serverPro = false;

  /// Bumped on every account change, so a load for the previous account
  /// that finishes late is dropped.
  int _generation = 0;

  bool get isPro => state.isPro;

  /// False when the free plan is already at its limit for [item] (the
  /// paywall should open instead of the add form).
  bool canAdd(LimitedItem item) => state.isPro || !state.status.item(item).isFull;

  /// False when today's [type] quota is used up.
  bool canUse(QuotaType type) => !state.status.quota(type).isUsedUp;

  Future<void> _onUserChanged(String? userId) async {
    _generation++;
    _userId = userId;
    _store = null;
    _serverPro = false;
    _safeEmit(const ProState());
    try {
      if (userId == null) {
        await _gateway.logOut();
        return;
      }
      await _gateway.logIn(userId);
    } catch (e, st) {
      // The store being unreachable never blocks the app: the free plan
      // and the server's status still apply.
      _logger.error('RevenueCat login/logout failed', error: e, stackTrace: st);
    }
    if (userId != null) await refresh();
  }

  /// Reads the plan and counters from the server.
  Future<void> refresh() async {
    if (_userId == null) return;
    final generation = _generation;
    try {
      final status = await _dataSource.getStatus();
      if (generation != _generation) return;
      _serverPro = status.isPro;
      final store = _store;
      _safeEmit(ProState(
        status: store != null && !status.isPro ? status.withStoreEntitlement(store) : status,
        hasLoadedOnce: true,
      ));
    } catch (e) {
      // Offline or the server is down: keep what's shown, and say so.
      _logger.warning('Loading the plan status failed', data: {'error': '$e'});
      if (generation != _generation) return;
      _safeEmit(ProState(status: state.status, hasLoadedOnce: state.hasLoadedOnce, loadFailed: true));
    }
  }

  void _scheduleRefresh() {
    _debounce?.cancel();
    _debounce = Timer(_refreshDebounce, refresh);
  }

  void _applyStore(ProEntitlement entitlement) {
    if (_userId == null) return;
    _store = entitlement;
    _safeEmit(ProState(
      status: state.status.withStoreEntitlement(entitlement),
      hasLoadedOnce: state.hasLoadedOnce,
      loadFailed: state.loadFailed,
    ));
  }

  /// A purchase or restore completed with [entitlement]: show Pro now, then
  /// re-read the server until the webhook has caught up (a few seconds).
  Future<void> applyPurchase(ProEntitlement entitlement, {int attempts = 5}) async {
    _applyStore(entitlement);
    if (!entitlement.isActive) {
      await refresh();
      return;
    }
    for (var i = 0; i < attempts; i++) {
      await refresh();
      if (isClosed || _serverPro) return;
      await Future<void>.delayed(_serverCatchUpInterval);
    }
  }

  void _safeEmit(ProState newState) {
    if (!isClosed) emit(newState);
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    return super.close();
  }
}
