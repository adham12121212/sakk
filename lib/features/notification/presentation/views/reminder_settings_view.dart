import 'package:flutter/material.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/service/installment_reminder_service.dart';
import '../../../../core/service/paper_reminder_service.dart';
import '../../../../core/service/reminder_controller.dart';
import '../../../../core/service/reminder_settings.dart';
import '../../../../core/service/subscription_reminder_service.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pro/presentation/pro_actions.dart';
import '../../../products/presentation/cubit/product_cubit.dart';

/// Reminders, opened from Profile: warranties, subscriptions, installments
/// and papers, each on or off, with when they arrive. Changes re-schedule
/// this phone's reminders straight away.
class ReminderSettingsView extends StatelessWidget {
  const ReminderSettingsView({super.key, this.settings, this.leadTime});

  /// For tests; the app-wide ones by default.
  final ReminderSettings? settings;
  final ReminderController? leadTime;

  // Each kind of reminder has its own colour on this screen.
  static const _subscriptionsColor = Color(0xFF8B5CF6);
  static const _installmentsColor = Color(0xFF3B82F6);
  static const _papersColor = Color(0xFFF97316);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = this.settings ?? getIt<ReminderSettings>();
    final leadTime = this.leadTime ?? getIt<ReminderController>();

    /// Saves the new lead time and moves every pending warranty reminder.
    Future<void> setLeadTime(int days) async {
      await leadTime.setDays(days);
      if (getIt.isRegistered<WarrantyNotificationService>()) {
        await getIt<WarrantyNotificationService>().rescheduleAll(
          getIt<ProductsCubit>().state.products,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reminders),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        top: false,
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, leadTime]),
          builder: (context, _) {
            final warrantyColor = context.palette.success;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  l10n.remindersIntro,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _ReminderSection(
                  icon: AppIcons.warranty,
                  color: warrantyColor,
                  title: l10n.reminderWarranties,
                  subtitle: l10n.reminderWarrantiesHint,
                  enabled: settings.warrantyEnabled,
                  onEnabled: settings.setWarrantyEnabled,
                  children: [
                    _Label(l10n.warrantyReminder),
                    _Pills(
                      color: warrantyColor,
                      options: {
                        90: l10n.reminder3Months,
                        30: l10n.reminder1Month,
                        7: l10n.reminder1Week,
                        1: l10n.reminder1Day,
                      },
                      isSelected: (days) => leadTime.value == days,
                      onTap: setLeadTime,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReminderSection(
                  icon: AppIcons.subscriptions,
                  color: _subscriptionsColor,
                  title: l10n.subscriptions,
                  subtitle: l10n.reminderSubscriptionsHint,
                  enabled: settings.subscriptionsEnabled,
                  onEnabled: settings.setSubscriptionsEnabled,
                  children: [
                    _KindPills<RenewalReminder>(
                      color: _subscriptionsColor,
                      options: {
                        RenewalReminder.threeDaysBefore:
                            l10n.reminderThreeDaysBefore,
                        RenewalReminder.dayBefore: l10n.reminderDayBefore,
                        RenewalReminder.dayAfter:
                            l10n.reminderDayAfterCheckCharge,
                      },
                      selected: settings.subscriptionKinds,
                      onChanged: settings.setSubscriptionKind,
                    ),
                    _ProLeadTime(
                      color: _subscriptionsColor,
                      days: settings.subscriptionCustomDays,
                      proActive: settings.proActive,
                      onChanged: settings.setSubscriptionCustomDays,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReminderSection(
                  icon: AppIcons.installments,
                  color: _installmentsColor,
                  title: l10n.installments,
                  subtitle: l10n.reminderInstallmentsHint,
                  enabled: settings.installmentsEnabled,
                  onEnabled: settings.setInstallmentsEnabled,
                  children: [
                    _KindPills<InstallmentReminder>(
                      color: _installmentsColor,
                      options: {
                        InstallmentReminder.threeDaysBefore:
                            l10n.reminderThreeDaysBefore,
                        InstallmentReminder.dueDay: l10n.reminderOnDueDay,
                      },
                      selected: settings.installmentKinds,
                      onChanged: settings.setInstallmentKind,
                    ),
                    _ProLeadTime(
                      color: _installmentsColor,
                      days: settings.installmentCustomDays,
                      proActive: settings.proActive,
                      onChanged: settings.setInstallmentCustomDays,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReminderSection(
                  icon: AppIcons.papers,
                  color: _papersColor,
                  title: l10n.myPapers,
                  subtitle: l10n.reminderPapersHint,
                  enabled: settings.papersEnabled,
                  onEnabled: settings.setPapersEnabled,
                  children: [
                    _KindPills<PaperReminder>(
                      color: _papersColor,
                      options: {
                        PaperReminder.monthBefore: l10n.reminderMonthBefore,
                        PaperReminder.weekBefore: l10n.reminderWeekBefore,
                        PaperReminder.expiryDay: l10n.reminderOnExpiryDay,
                      },
                      selected: settings.paperKinds,
                      onChanged: settings.setPaperKind,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// One kind of reminder in its own colour: a header with its switch, and
/// when it's on, [children] (what the user can choose).
class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabled,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: InkWell(
              onTap: () => onEnabled(!enabled),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: enabled ? 0.14 : 0.07),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        icon,
                        size: 21,
                        color: enabled ? color : color.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: textTheme.titleMedium),
                          Text(subtitle, style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: enabled,
                      onChanged: onEnabled,
                      activeTrackColor: color,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: enabled
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Pills that wrap: filled in [color] with white text when selected, an
/// outline with grey text when not.
class _Pills<T> extends StatelessWidget {
  const _Pills({
    required this.color,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.enabled,
  });

  final Color color;
  final Map<T, String> options;
  final bool Function(T value) isSelected;

  /// Null when that pill can't be changed (the last one left on).
  final ValueChanged<T> onTap;
  final bool Function(T value)? enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final MapEntry(key: value, value: label) in options.entries)
          Builder(
            builder: (context) {
              final selected = isSelected(value);
              final canTap = enabled?.call(value) ?? true;
              return Semantics(
                button: true,
                selected: selected,
                enabled: canTap,
                child: Material(
                  color: selected ? color : Colors.transparent,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: selected ? color : colorScheme.outlineVariant,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: canTap ? () => onTap(value) : null,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (selected) ...[
                              const Icon(
                                AppIcons.check,
                                size: 15,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: selected
                                          ? Colors.white
                                          : colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Which reminders of one kind to get, as pills. The last one left can't
/// be turned off: the switch above turns them all off.
class _KindPills<T> extends StatelessWidget {
  const _KindPills({
    required this.color,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Color color;
  final Map<T, String> options;
  final Set<T> selected;
  final void Function(T kind, bool on) onChanged;

  @override
  Widget build(BuildContext context) {
    return _Pills<T>(
      color: color,
      options: options,
      isSelected: selected.contains,
      enabled: (kind) => !(selected.contains(kind) && selected.length == 1),
      onTap: (kind) => onChanged(kind, !selected.contains(kind)),
    );
  }
}

/// Sakk Pro's extra reminder: off, or a number of days ahead. Free users
/// see the choices locked (on "Off"); picking one opens the paywall. A
/// choice made while Pro is saved, and comes back if Pro does.
class _ProLeadTime extends StatelessWidget {
  const _ProLeadTime({
    required this.color,
    required this.days,
    required this.proActive,
    required this.onChanged,
  });

  final Color color;
  final int? days;
  final bool proActive;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);

    void pick(int? value) {
      if (!proActive) {
        ProActions.openPaywall(context);
        return;
      }
      onChanged(value);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: colorScheme.outlineVariant),
          const SizedBox(height: 14),
          _Label(
            l10n.reminderCustomTitle,
            trailing: proActive
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.locked,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.reminderCustomProOnly,
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(l10n.reminderCustomHint, style: textTheme.bodySmall),
          ),
          Opacity(
            opacity: proActive ? 1 : 0.6,
            child: _Pills<int?>(
              color: color,
              options: {
                null: l10n.reminderCustomOff,
                for (final value in ReminderSettings.customDayOptions)
                  value: l10n.reminderCustomDays(
                    value,
                    formatLocalizedInt(locale, value),
                  ),
              },
              isSelected: (value) => proActive ? days == value : value == null,
              onTap: pick,
            ),
          ),
        ],
      ),
    );
  }
}
