import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';

/// "Add to calendar" for the warranty end date and, while it's still open,
/// the return deadline. Opens the phone's calendar with the event filled in,
/// so the user sees it and saves it there.
class CalendarActions extends StatelessWidget {
  const CalendarActions({super.key, required this.product});

  final ProductEntity product;

  Future<void> _add(BuildContext context, {required String title, required DateTime date}) async {
    final l10n = AppLocalizations.of(context)!;
    final day = DateTime(date.year, date.month, date.day);
    bool opened;
    try {
      opened = await Add2Calendar.addEvent2Cal(Event(
        title: title,
        description: l10n.calendarEventDescription(product.name),
        startDate: day,
        // The next calendar day, not +24h (off by an hour across a DST change).
        endDate: DateTime(day.year, day.month, day.day + 1),
        allDay: true,
      ));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) AppSnackBar.error(context, l10n.couldNotOpenCalendar);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final returnBy = product.returnByDate;
    final returnOpen = returnBy != null && (product.daysToReturn ?? -1) >= 0;
    if (product.isExpired && !returnOpen) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: [
          if (!product.isExpired)
            TextButton.icon(
              onPressed: () => _add(context, title: l10n.calendarWarrantyEnds(product.name), date: product.warrantyEndDate),
              icon: const Icon(AppIcons.calendar, size: 18),
              label: Text(l10n.addWarrantyEndToCalendar),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
          if (returnOpen)
            TextButton.icon(
              onPressed: () => _add(context, title: l10n.calendarReturnDeadline(product.name), date: returnBy),
              icon: const Icon(AppIcons.calendar, size: 18),
              label: Text(l10n.addReturnDeadlineToCalendar),
              style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
        ],
      ),
    );
  }
}
