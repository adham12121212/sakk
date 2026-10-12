import 'entities/billing_cycle.dart';

/// [date] moved by [months], keeping its day of the month where it exists
/// and using the month's last day where it doesn't (Jan 31 + 1 → Feb 28).
DateTime addMonthsClamped(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + (monthIndex ~/ 12);
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day);
}

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
