import 'package:flutter/material.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/service/installment_reminder_service.dart';
import '../../../../core/service/reminder_controller.dart';
import '../../../../core/service/reminder_settings.dart';
import '../../../../core/service/subscription_reminder_service.dart';
import '../../../../core/service/warranty_notification_service.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/widgets/segmented_toggle.dart';
import '../../../pro/presentation/pro_actions.dart';
import '../../../products/presentation/cubit/product_cubit.dart';

/// Reminders, opened from Profile: warranties, subscriptions and
/// installments, each on or off, with when they arrive. Changes re-schedule
/// this phone's reminders straight away.
class ReminderSettingsView extends StatelessWidget {
  const ReminderSettingsView({super.key, this.settings, this.leadTime});

  /// For tests; the app-wide ones by default.
  final ReminderSettings? settings;
  final ReminderController? leadTime;

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
          builder: (context, _) => ListView(
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
                title: l10n.reminderWarranties,
                subtitle: l10n.reminderWarrantiesHint,
                enabled: settings.warrantyEnabled,
                onEnabled: settings.setWarrantyEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.warrantyReminder,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    SegmentedToggle<int>(
                      options: {
                        90: l10n.reminder3Months,
                        30: l10n.reminder1Month,
                        7: l10n.reminder1Week,
                        1: l10n.reminder1Day,
                      },
                      selected: leadTime.value,
                      onChanged: setLeadTime,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ReminderSection(
                icon: AppIcons.subscriptions,
                title: l10n.subscriptions,
                subtitle: l10n.reminderSubscriptionsHint,
                enabled: settings.subscriptionsEnabled,
                onEnabled: settings.setSubscriptionsEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _KindChoices<RenewalReminder>(
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
                      days: settings.subscriptionCustomDays,
                      proActive: settings.proActive,
                      onChanged: settings.setSubscriptionCustomDays,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ReminderSection(
                icon: AppIcons.installments,
                title: l10n.installments,
                subtitle: l10n.reminderInstallmentsHint,
                enabled: settings.installmentsEnabled,
                onEnabled: settings.setInstallmentsEnabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _KindChoices<InstallmentReminder>(
                      options: {
                        InstallmentReminder.threeDaysBefore:
                            l10n.reminderThreeDaysBefore,
                        InstallmentReminder.dueDay: l10n.reminderOnDueDay,
                      },
                      selected: settings.installmentKinds,
                      onChanged: settings.setInstallmentKind,
                    ),
                    _ProLeadTime(
                      days: settings.installmentCustomDays,
                      proActive: settings.proActive,
                      onChanged: settings.setInstallmentCustomDays,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One kind of reminder: a switch in the header, and when it's on, what
/// [child] lets the user choose.
class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEnabled,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onEnabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(fontSize: 15),
                      ),
                      Text(subtitle, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(value: enabled, onChanged: onEnabled),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }
}

/// Which reminders of one kind to get. The last one left can't be unticked:
/// the switch above turns them all off.
class _KindChoices<T> extends StatelessWidget {
  const _KindChoices({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<T, String> options;
  final Set<T> selected;
  final void Function(T kind, bool on) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final MapEntry(key: kind, value: label) in options.entries)
          CheckboxListTile(
            value: selected.contains(kind),
            title: Text(label),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: selected.contains(kind) && selected.length == 1
                ? null
                : (on) => onChanged(kind, on ?? false),
          ),
      ],
    );
  }
}

/// Sakk Pro's extra reminder: off, or a number of days ahead. Free users
/// see the choices locked (on "Off"); picking one opens the paywall. A
/// choice made while Pro is saved, and comes back if Pro does.
class _ProLeadTime extends StatelessWidget {
  const _ProLeadTime({
    required this.days,
    required this.proActive,
    required this.onChanged,
  });

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
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.reminderCustomTitle,
                  style: textTheme.bodyMedium,
                ),
              ),
              if (!proActive) ...[
                Icon(
                  AppIcons.locked,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(l10n.reminderCustomProOnly, style: textTheme.labelMedium),
              ],
            ],
          ),
          Text(l10n.reminderCustomHint, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          Opacity(
            opacity: proActive ? 1 : 0.6,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in [
                  null,
                  ...ReminderSettings.customDayOptions,
                ])
                  ChoiceChip(
                    label: Text(
                      value == null
                          ? l10n.reminderCustomOff
                          : l10n.reminderCustomDays(
                              value,
                              formatLocalizedInt(locale, value),
                            ),
                    ),
                    selected: proActive ? days == value : value == null,
                    onSelected: (_) => pick(value),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
