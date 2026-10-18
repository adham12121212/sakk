/// [day] of [month] in [year], or that month's last day when the month is
/// shorter (Feb 31 → Feb 28). [month] may run past 12 or below 1, as with
/// [DateTime]'s own constructor.
DateTime clampedDate(int year, int month, int day) {
  final first = DateTime(year, month);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, day > lastDay ? lastDay : day);
}

/// [date] moved by [months] (negative goes back), keeping its day of the
/// month where it exists and using the month's last day where it doesn't
/// (Jan 31 + 1 → Feb 28).
DateTime addMonthsClamped(DateTime date, int months) =>
    clampedDate(date.year, date.month + months, date.day);

/// [date] without its time of day.
DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Whole days from [from] to [to], ignoring the time of day (UTC, so a
/// daylight-saving change can't make a day 23 hours long).
int daysBetween(DateTime from, DateTime to) =>
    DateTime.utc(to.year, to.month, to.day)
        .difference(DateTime.utc(from.year, from.month, from.day))
        .inDays;
