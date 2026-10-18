import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../util/installment_format.dart';

/// One row of the preview.
class PreviewRow {
  const PreviewRow({required this.dueDate, required this.amount, this.isPaid = false});

  final DateTime dueDate;
  final double amount;

  /// Already paid (when editing): kept as it is.
  final bool isPaid;
}

/// The form's live preview of the schedule it will save: a summary line,
/// then the first few installments with "Show all".
class SchedulePreview extends StatefulWidget {
  const SchedulePreview({
    super.key,
    required this.rows,
    required this.currency,
    required this.downPayment,
  });

  /// Earliest first.
  final List<PreviewRow> rows;
  final String currency;
  final double downPayment;

  @override
  State<SchedulePreview> createState() => _SchedulePreviewState();
}

class _SchedulePreviewState extends State<SchedulePreview> {
  static const _collapsedRows = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final rows = widget.rows;
    final total = widget.downPayment + rows.fold(0.0, (sum, r) => sum + r.amount);
    final shown = _expanded || rows.length <= _collapsedRows + 1 ? rows : rows.take(_collapsedRows).toList();
    String money(double v) => formatMoney(context, v, widget.currency);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(AppIcons.calendar, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.schedulePreview, style: textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(
              l10n.schedulePreviewEmpty,
              style: textTheme.bodySmall?.copyWith(fontSize: 13),
            )
          else ...[
            Text(
              l10n.schedulePreviewSummary(
                rows.length,
                formatCount(context, rows.length),
                money(total),
                formatInstallmentDate(context, rows.last.dueDate),
              ),
              style: textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 8),
            for (final (i, row) in shown.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        formatCount(context, i + 1),
                        style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(child: Text(formatInstallmentDate(context, row.dueDate), style: textTheme.bodyMedium)),
                    if (row.isPaid) ...[
                      Icon(AppIcons.successFilled, size: 16, color: context.palette.success),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      money(row.amount),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: row.isPaid ? colorScheme.onSurfaceVariant : null,
                      ),
                    ),
                  ],
                ),
              ),
            if (shown.length < rows.length || _expanded && rows.length > _collapsedRows + 1)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44), padding: EdgeInsets.zero),
                  child: Text(
                    _expanded
                        ? l10n.showLess
                        : l10n.showAllInstallments(rows.length, formatCount(context, rows.length)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
