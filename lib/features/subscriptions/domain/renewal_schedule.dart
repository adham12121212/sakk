import '../../../core/util/date_math.dart';
import 'entities/billing_cycle.dart';
import 'entities/user_subscription.dart';

// Moved to core (installments use it too); re-exported for existing imports.
export '../../../core/util/date_math.dart' show addMonthsClamped;

/// The first renewal on or after [today], counting whole [cycle]s from
/// [renewalDate]. Returns [renewalDate] itself if it hasn't passed.
///
/// Always counts from the original date, so a subscription that renews on
/// the 31st goes back to the 31st after a short month instead of drifting
/// (Jan 31 → Feb 28 → Mar 31).
DateTime nextRenewalOnOrAfter(
  DateTime renewalDate,
  BillingCycle cycle,
  DateTime today,
) {
  final start = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
  final day = DateTime(today.year, today.month, today.day);
  if (!start.isBefore(day)) return start;

  // Jump close in one step, then walk the last cycle or two.
  final monthsBehind = (day.year - start.year) * 12 + day.month - start.month;
  var cycles = (monthsBehind ~/ cycle.months).clamp(1, 1 << 30);
  var next = addMonthsClamped(start, cycles * cycle.months);
  while (next.isBefore(day)) {
    cycles++;
    next = addMonthsClamped(start, cycles * cycle.months);
  }
  return next;
}

/// [subscriptions] with every renewal that already passed moved to its next
/// one on or after [today]. Unchanged subscriptions are returned as they are.
List<UserSubscription> advancePassedRenewals(Iterable<UserSubscription> subscriptions, DateTime today) {
  return [
    for (final s in subscriptions)
      s.daysLeft(today) < 0
          ? s.copyWith(nextRenewalDate: nextRenewalOnOrAfter(s.nextRenewalDate, s.billingCycle, today))
          : s,
  ];
}
