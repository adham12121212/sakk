import '../../../core/util/date_math.dart';
import 'entities/billing_cycle.dart';
import 'entities/user_subscription.dart';

// Moved to core (installments use it too); re-exported for existing imports.
export '../../../core/util/date_math.dart' show addMonthsClamped;

/// The first renewal on or after [today], counting whole [cycle]s from
/// [renewalDate]. Returns [renewalDate] itself if it hasn't passed.
///
/// Each renewal lands on [day] of its month (default: [renewalDate]'s), or
/// the month's last day when it's shorter, so one that renews on the 31st
/// goes back to the 31st after a short month (Jan 31 → Feb 28 → Mar 31),
/// even counting from the stored Feb 28.
DateTime nextRenewalOnOrAfter(
  DateTime renewalDate,
  BillingCycle cycle,
  DateTime today, {
  int? day,
}) {
  final start = DateTime(renewalDate.year, renewalDate.month, renewalDate.day);
  final from = DateTime(today.year, today.month, today.day);
  if (!start.isBefore(from)) return start;
  final billingDay = day ?? start.day;
  DateTime after(int cycles) =>
      clampedDate(start.year, start.month + cycles * cycle.months, billingDay);

  // Jump close in one step, then walk the last cycle or two.
  final monthsBehind = (from.year - start.year) * 12 + from.month - start.month;
  var cycles = (monthsBehind ~/ cycle.months).clamp(1, 1 << 30);
  var next = after(cycles);
  while (next.isBefore(from)) {
    cycles++;
    next = after(cycles);
  }
  return next;
}

/// [subscriptions] with every renewal that already passed moved to its next
/// one on or after [today]. Unchanged subscriptions are returned as they are.
List<UserSubscription> advancePassedRenewals(
  Iterable<UserSubscription> subscriptions,
  DateTime today,
) {
  return [
    for (final s in subscriptions)
      s.daysLeft(today) < 0
          ? s.copyWith(
              nextRenewalDate: nextRenewalOnOrAfter(
                s.nextRenewalDate,
                s.billingCycle,
                today,
                day: s.billingDay,
              ),
            )
          : s,
  ];
}
