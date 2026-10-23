import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'installment_reminder_service.dart';
import 'subscription_reminder_service.dart';

/// Which reminders the user wants, from the Reminders screen: warranties on
/// or off, and for subscriptions and installments on or off plus which of
/// their reminders. Saved per device, like the theme. Everything is on by
/// default. (How early the warranty reminder comes is [ReminderController].)
///
/// Sakk Pro adds one more reminder for subscriptions and installments, a
/// number of days ahead the user picks ([RenewalReminder.custom],
/// [InstallmentReminder.custom]). The choice is kept when Pro ends but only
/// applies while [proActive] is true.
///
/// The reminder services listen to this and re-sync when it changes.
class ReminderSettings extends ChangeNotifier {
  ReminderSettings() {
    ready = _loadSaved();
  }

  /// Completes once the saved choices are loaded; await it before scheduling.
  late final Future<void> ready;

  bool _warrantyEnabled = true;
  bool _subscriptionsEnabled = true;
  bool _installmentsEnabled = true;
  Set<RenewalReminder> _subscriptionKinds = _defaultSubscriptionKinds;
  Set<InstallmentReminder> _installmentKinds = _defaultInstallmentKinds;
  int? _subscriptionCustomDays;
  int? _installmentCustomDays;
  bool _proActive = false;

  /// The ticked-by-default kinds: all but the Pro one, which is set by
  /// picking a number of days.
  static final _defaultSubscriptionKinds = RenewalReminder.values
      .where((k) => k != RenewalReminder.custom)
      .toSet();
  static final _defaultInstallmentKinds = InstallmentReminder.values
      .where((k) => k != InstallmentReminder.custom)
      .toSet();

  /// The days-ahead choices for the Pro reminder.
  static const customDayOptions = [5, 7, 10, 14];

  bool get warrantyEnabled => _warrantyEnabled;
  bool get subscriptionsEnabled => _subscriptionsEnabled;
  bool get installmentsEnabled => _installmentsEnabled;

  /// The subscription reminders chosen; kept while the switch is off, so
  /// turning it back on restores them.
  Set<RenewalReminder> get subscriptionKinds =>
      Set.unmodifiable(_subscriptionKinds);
  Set<InstallmentReminder> get installmentKinds =>
      Set.unmodifiable(_installmentKinds);

  /// The Pro reminder's days ahead as chosen (null: off), whether or not
  /// Pro is active now.
  int? get subscriptionCustomDays => _subscriptionCustomDays;
  int? get installmentCustomDays => _installmentCustomDays;

  /// The days ahead to use for the Pro reminder right now: null unless Pro.
  int? get activeSubscriptionCustomDays =>
      _proActive ? _subscriptionCustomDays : null;
  int? get activeInstallmentCustomDays =>
      _proActive ? _installmentCustomDays : null;

  bool get proActive => _proActive;

  /// Whether [kind] should be scheduled and shown right now.
  bool wantsSubscription(RenewalReminder kind) =>
      _subscriptionsEnabled &&
      (kind == RenewalReminder.custom
          ? activeSubscriptionCustomDays != null
          : _subscriptionKinds.contains(kind));
  bool wantsInstallment(InstallmentReminder kind) =>
      _installmentsEnabled &&
      (kind == InstallmentReminder.custom
          ? activeInstallmentCustomDays != null
          : _installmentKinds.contains(kind));

  static const _warrantyKey = 'reminders_warranty_enabled';
  static const _subscriptionsKey = 'reminders_subscriptions_enabled';
  static const _subscriptionKindsKey = 'reminders_subscription_kinds';
  static const _installmentsKey = 'reminders_installments_enabled';
  static const _installmentKindsKey = 'reminders_installment_kinds';
  static const _subscriptionCustomDaysKey =
      'reminders_subscription_custom_days';
  static const _installmentCustomDaysKey = 'reminders_installment_custom_days';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _warrantyEnabled = prefs.getBool(_warrantyKey) ?? true;
    _subscriptionsEnabled = prefs.getBool(_subscriptionsKey) ?? true;
    _installmentsEnabled = prefs.getBool(_installmentsKey) ?? true;
    _subscriptionKinds = _kinds(
      prefs.getStringList(_subscriptionKindsKey),
      _defaultSubscriptionKinds,
    );
    _installmentKinds = _kinds(
      prefs.getStringList(_installmentKindsKey),
      _defaultInstallmentKinds,
    );
    _subscriptionCustomDays = _days(prefs.getInt(_subscriptionCustomDaysKey));
    _installmentCustomDays = _days(prefs.getInt(_installmentCustomDaysKey));
    notifyListeners();
  }

  static int? _days(int? saved) =>
      customDayOptions.contains(saved) ? saved : null;

  /// Saved names back to kinds; names an older or newer version wrote that
  /// don't exist here are skipped, and nothing usable means all of them.
  static Set<T> _kinds<T extends Enum>(List<String>? saved, Set<T> values) {
    final kinds = {
      for (final name in saved ?? const <String>[])
        ...values.where((v) => v.name == name),
    };
    return kinds.isEmpty ? {...values} : kinds;
  }

  /// Follows the plan (from ProCubit). The Pro reminders start and stop
  /// with it; the reminder services re-sync when this changes.
  void setProActive(bool active) {
    if (active == _proActive) return;
    _proActive = active;
    notifyListeners();
  }

  /// The Pro reminder for subscriptions, [days] ahead (null: off).
  Future<void> setSubscriptionCustomDays(int? days) => _save(
    () => _subscriptionCustomDays = days,
    (p) => days == null
        ? p.remove(_subscriptionCustomDaysKey)
        : p.setInt(_subscriptionCustomDaysKey, days),
  );

  /// The Pro reminder for installments, [days] ahead (null: off).
  Future<void> setInstallmentCustomDays(int? days) => _save(
    () => _installmentCustomDays = days,
    (p) => days == null
        ? p.remove(_installmentCustomDaysKey)
        : p.setInt(_installmentCustomDaysKey, days),
  );

  Future<void> setWarrantyEnabled(bool enabled) => _save(
    () => _warrantyEnabled = enabled,
    (p) => p.setBool(_warrantyKey, enabled),
  );

  Future<void> setSubscriptionsEnabled(bool enabled) => _save(
    () => _subscriptionsEnabled = enabled,
    (p) => p.setBool(_subscriptionsKey, enabled),
  );

  Future<void> setInstallmentsEnabled(bool enabled) => _save(
    () => _installmentsEnabled = enabled,
    (p) => p.setBool(_installmentsKey, enabled),
  );

  /// Turns one subscription reminder on or off. The last one can't be
  /// turned off: the switch is for stopping them all.
  Future<void> setSubscriptionKind(RenewalReminder kind, bool on) async {
    final next = {..._subscriptionKinds};
    on ? next.add(kind) : next.remove(kind);
    if (next.isEmpty) return;
    await _save(
      () => _subscriptionKinds = next,
      (p) => p.setStringList(_subscriptionKindsKey, [
        for (final k in next) k.name,
      ]),
    );
  }

  /// Turns one installment reminder on or off; the last one stays on.
  Future<void> setInstallmentKind(InstallmentReminder kind, bool on) async {
    final next = {..._installmentKinds};
    on ? next.add(kind) : next.remove(kind);
    if (next.isEmpty) return;
    await _save(
      () => _installmentKinds = next,
      (p) =>
          p.setStringList(_installmentKindsKey, [for (final k in next) k.name]),
    );
  }

  Future<void> _save(
    void Function() apply,
    Future<bool> Function(SharedPreferences) persist,
  ) async {
    apply();
    notifyListeners();
    await persist(await SharedPreferences.getInstance());
  }
}
