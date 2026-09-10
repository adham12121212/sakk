
import 'package:intl/intl.dart';

extension DateFormatting on DateTime {
  String toShortLabel(String locale) => DateFormat.MMMd(locale).format(this);

  String toIsoDate() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}