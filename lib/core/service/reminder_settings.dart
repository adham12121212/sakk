import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'installment_reminder_service.dart';
import 'subscription_reminder_service.dart';

/// Which reminders the user wants, from the Reminders screen: warranties on
/// or off, and for subscriptions and installments on or off plus which of
/// their reminders. Saved per device, like the theme. Everything is on by
/// default. (How early the warranty reminder comes is [ReminderController].)
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
  Set<RenewalReminder> _subscriptionKinds = RenewalReminder.values.toSet();
  Set<InstallmentReminder> _installmentKinds = InstallmentReminder.values.toSet();

  bool get warrantyEnabled => _warrantyEnabled;
  bool get subscriptionsEnabled => _subscriptionsEnabled;
  bool get installmentsEnabled => _installmentsEnabled;

  /// The subscription reminders chosen; kept while the switch is off, so
  /// turning it back on restores them.
  Set<RenewalReminder> get subscriptionKinds => Set.unmodifiable(_subscriptionKinds);
  Set<InstallmentReminder> get installmentKinds => Set.unmodifiable(_installmentKinds);

  /// Whether [kind] should be scheduled and shown right now.
  bool wantsSubscription(RenewalReminder kind) => _subscriptionsEnabled && _subscriptionKinds.contains(kind);
  bool wantsInstallment(InstallmentReminder kind) => _installmentsEnabled && _installmentKinds.contains(kind);

  static const _warrantyKey = 'reminders_warranty_enabled';
  static const _subscriptionsKey = 'reminders_subscriptions_enabled';
  static const _subscriptionKindsKey = 'reminders_subscription_kinds';
  static const _installmentsKey = 'reminders_installments_enabled';
  static const _installmentKindsKey = 'reminders_installment_kinds';

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _warrantyEnabled = prefs.getBool(_warrantyKey) ?? true;
    _subscriptionsEnabled = prefs.getBool(_subscriptionsKey) ?? true;
    _installmentsEnabled = prefs.getBool(_installmentsKey) ?? true;
    _subscriptionKinds = _kinds(prefs.getStringList(_subscriptionKindsKey), RenewalReminder.values);
    _installmentKinds = _kinds(prefs.getStringList(_installmentKindsKey), InstallmentReminder.values);
    notifyListeners();
  }

  /// Saved names back to kinds; names an older or newer version wrote that
  /// don't exist here are skipped, and nothing usable means all of them.
  static Set<T> _kinds<T extends Enum>(List<String>? saved, List<T> values) {
    final kinds = {
      for (final name in saved ?? const <String>[])
        ...values.where((v) => v.name == name),
    };
    return kinds.isEmpty ? values.toSet() : kinds;
  }

  Future<void> setWarrantyEnabled(bool enabled) =>
      _save(() => _warrantyEnabled = enabled, (p) => p.setBool(_warrantyKey, enabled));

  Future<void> setSubscriptionsEnabled(bool enabled) =>
      _save(() => _subscriptionsEnabled = enabled, (p) => p.setBool(_subscriptionsKey, enabled));

  Future<void> setInstallmentsEnabled(bool enabled) =>
      _save(() => _installmentsEnabled = enabled, (p) => p.setBool(_installmentsKey, enabled));

  /// Turns one subscription reminder on or off. The last one can't be
  /// turned off: the switch is for stopping them all.
  Future<void> setSubscriptionKind(RenewalReminder kind, bool on) async {
    final next = {..._subscriptionKinds};
    on ? next.add(kind) : next.remove(kind);
    if (next.isEmpty) return;
    await _save(
      () => _subscriptionKinds = next,
      (p) => p.setStringList(_subscriptionKindsKey, [for (final k in next) k.name]),
    );
  }

  /// Turns one installment reminder on or off; the last one stays on.
  Future<void> setInstallmentKind(InstallmentReminder kind, bool on) async {
    final next = {..._installmentKinds};
    on ? next.add(kind) : next.remove(kind);
    if (next.isEmpty) return;
    await _save(
      () => _installmentKinds = next,
      (p) => p.setStringList(_installmentKindsKey, [for (final k in next) k.name]),
    );
  }

  Future<void> _save(void Function() apply, Future<bool> Function(SharedPreferences) persist) async {
    apply();
    notifyListeners();
    await persist(await SharedPreferences.getInstance());
  }
}
