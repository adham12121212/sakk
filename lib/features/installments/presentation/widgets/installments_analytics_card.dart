import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/installment_totals.dart';
import '../cubit/installments_state.dart';
import '../util/installment_format.dart';

/// Analytics card: what's left to pay, what's overdue, and what installments
/// cost each month for the next six months. Amounts in other currencies are
/// listed but not added in (no exchange rates), so the chart covers the
/// main currency.
class InstallmentsAnalyticsCard extends StatefulWidget {
  const InstallmentsAnalyticsCard({
    super.key,
    required this.state,
    required this.onTap,
    this.today,
  });

  final InstallmentsState state;
  final VoidCallback onTap;

  /// For tests; defaults to now.
  final DateTime? today;

  @override
  State<InstallmentsAnalyticsCard> createState() =>
      _InstallmentsAnalyticsCardState();
}

class _InstallmentsAnalyticsCardState extends State<InstallmentsAnalyticsCard> {
  /// The bar whose amount is shown; the current month until one is tapped.
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final state = widget.state;
    final today = widget.today ?? DateTime.now();
    final isInitialLoading = state.isLoading && !state.hasLoadedOnce;
    final hasPlans = state.plans.any((p) => !p.isCancelled);

    final remaining = state.remainingTotals;
    final main = remaining.containsKey('EGP') || remaining.isEmpty
        ? 'EGP'
        : remaining.keys.first;
    final others = remaining.entries.where((e) => e.key != main).toList();
    final overdue = overdueByCurrency(state.plans, today);
    final months = isInitialLoading
        ? [
            for (var i = 0; i < 6; i++)
              (
                year: today.year,
                month: today.month + i,
                amount: 1000.0 + i * 150,
              ),
          ]
        : dueByMonth(state.plans, from: today, currency: main);

    return AppCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.installments, style: textTheme.titleMedium),
          const SizedBox(height: 16),
          if (!isInitialLoading && !hasPlans)
            Text(
              l10n.installmentsAnalyticsEmpty,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            Skeletonizer(
              enabled: isInitialLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Figure(
                          label: l10n.installmentsLeftToPay,
                          value: formatMoney(
                            context,
                            isInitialLoading ? 12000 : remaining[main] ?? 0,
                            main,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Figure(
                          label: l10n.installmentsThisMonth,
                          value: formatMoney(
                            context,
                            months.first.amount,
                            main,
                          ),
                        ),
                      ),
                    ],
                  ),
                  for (final other in others)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '+ ${formatMoney(context, other.value, other.key)}',
                        style: textTheme.bodySmall,
                      ),
                    ),
                  if (overdue.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // Status: red with an icon and words, never colour alone.
                    Row(
                      children: [
                        Icon(
                          AppIcons.warning,
                          size: 16,
                          color: context.palette.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            l10n.installmentsOverdueTotal(
                              formatTotals(context, overdue),
                            ),
                            style: textTheme.bodySmall?.copyWith(
                              color: context.palette.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    l10n.installmentsDuePerMonth,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _MonthlyBars(
                    months: months,
                    currency: main,
                    selected: _selected.clamp(0, months.length - 1),
                    onSelect: (i) => setState(() => _selected = i),
                  ),
                  if (others.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.installmentsChartCurrencyNote(
                        main == 'EGP' ? l10n.currencyEgp : main,
                      ),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: textTheme.bodySmall),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// One bar per month, in one hue (a single series needs no legend). The
/// selected month's amount is written above its bar; tap another to see
/// it. Each bar also reads out its month and amount to screen readers.
class _MonthlyBars extends StatelessWidget {
  const _MonthlyBars({
    required this.months,
    required this.currency,
    required this.selected,
    required this.onSelect,
  });

  final List<MonthlyDue> months;
  final String currency;
  final int selected;
  final ValueChanged<int> onSelect;

  static const _barAreaHeight = 112.0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final tag = locale.languageCode == 'ar' ? 'ar_EG' : locale.toLanguageTag();
    final monthFormat = DateFormat.MMM(tag);
    final max = months.fold(0.0, (m, e) => e.amount > m ? e.amount : m);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The selected value, above the bars so it never collides with them.
        Text(
          '${monthFormat.format(DateTime(months[selected].year, months[selected].month))} · '
          '${formatMoney(context, months[selected].amount, currency)}',
          textAlign: TextAlign.center,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _barAreaHeight + 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final (i, m) in months.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == selected,
                    label:
                        '${monthFormat.format(DateTime(m.year, m.month))}: ${formatMoney(context, m.amount, currency)}',
                    child: ExcludeSemantics(
                      child: InkWell(
                        onTap: () => onSelect(i),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          // A 2px+ gap of surface between neighbouring bars.
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: max <= 0
                                    ? 0
                                    : (m.amount / max * _barAreaHeight).clamp(
                                        m.amount > 0 ? 4.0 : 0.0,
                                        _barAreaHeight,
                                      ),
                                decoration: BoxDecoration(
                                  color: i == selected
                                      ? colorScheme.primary
                                      : colorScheme.primary.withValues(
                                          alpha: 0.45,
                                        ),
                                  // Rounded data end, square on the baseline.
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              // Recessive baseline.
                              Container(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                monthFormat.format(DateTime(m.year, m.month)),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: i == selected
                                      ? FontWeight.w700
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
