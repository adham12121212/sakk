
extension DateFormatting on DateTime {
  static const _monthAbbreviations = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String toShortLabel() => '${_monthAbbreviations[month - 1]} $day, $year';

  String toIsoDate() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}