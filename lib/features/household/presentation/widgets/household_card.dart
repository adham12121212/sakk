import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/domain/usecase/get_user_usecase.dart';
import '../cubit/household_cubit.dart';

class HouseholdCard extends StatefulWidget {
  const HouseholdCard({super.key});

  @override
  State<HouseholdCard> createState() => _HouseholdCardState();
}

class _HouseholdCardState extends State<HouseholdCard> {
  final _cubit = getIt<HouseholdCubit>();

  String? get _myId => getIt<GetUserUseCase>()()?.id;

  String get _myName {
    final user = getIt<GetUserUseCase>()();
    if (user == null) return '';
    return user.name.trim().isNotEmpty
        ? user.name.trim()
        : user.email.split('@').first;
  }

  @override
  void initState() {
    super.initState();
    _cubit.load();
  }

  Future<void> _run(Future<bool> Function() action, {String? success}) async {
    final ok = await action();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (ok) {
      if (success != null) AppSnackBar.success(context, success);
    } else {
      AppSnackBar.error(context, userFacingError(l10n, _cubit.state.error));
    }
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final name = await _askText(
      context,
      title: l10n.createHousehold,
      label: l10n.householdName,
      hint: l10n.householdNameHint,
    );
    if (name == null) return;
    await _run(
      () => _cubit.create(name, _myName),
      success: l10n.householdCreated,
    );
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context)!;
    final code = await _askText(
      context,
      title: l10n.joinHousehold,
      label: l10n.inviteCode,
      hint: 'A1B2C3D4E5',
      upperCase: true,
    );
    if (code == null) return;
    await _run(() => _cubit.join(code, _myName), success: l10n.householdJoined);
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.leaveHouseholdQuestion,
      body: l10n.leaveHouseholdBody,
      action: l10n.leaveHousehold,
    );
    if (confirmed) await _run(_cubit.leave);
  }

  Future<void> _remove(String userId, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirm(
      context,
      title: l10n.removeMemberQuestion(name),
      body: l10n.removeMemberBody,
      action: l10n.removeMember,
    );
    if (confirmed) await _run(() => _cubit.removeMember(userId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<HouseholdCubit, HouseholdState>(
      bloc: _cubit,
      builder: (context, state) {
        final household = state.household;
        final busy = state.isBusy;

        if (household == null) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(AppIcons.household, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.familySharing,
                        style: textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.familySharingHint,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: busy || state.isLoading ? null : _create,
                        child: Text(l10n.createHousehold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy || state.isLoading ? null : _join,
                        child: Text(l10n.joinHousehold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final iAmOwner = state.isOwner(_myId);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(AppIcons.household, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(household.name, style: textTheme.titleSmall),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.householdSharedHint,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.inviteCode,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      household.inviteCode,
                      style: textTheme.titleLarge?.copyWith(
                        letterSpacing: 2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.copyInviteCode,
                    icon: const Icon(AppIcons.copy),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: household.inviteCode),
                      );
                      if (context.mounted) {
                        AppSnackBar.success(context, l10n.inviteCodeCopied);
                      }
                    },
                  ),
                  IconButton(
                    tooltip: l10n.shareInviteCode,
                    icon: const Icon(AppIcons.share),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text: l10n.inviteMessage(
                          household.name,
                          household.inviteCode,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (iAmOwner)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => _run(
                            _cubit.regenerateInviteCode,
                            success: l10n.newInviteCodeCreated,
                          ),
                    child: Text(l10n.newInviteCode),
                  ),
                ),
              const Divider(height: 24),
              Text(
                l10n.householdMembers,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              for (final member in state.members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    member.userId == _myId
                        ? l10n.memberYou(member.displayName)
                        : member.displayName,
                  ),
                  subtitle: member.isOwner ? Text(l10n.householdOwner) : null,
                  trailing: iAmOwner && member.userId != _myId
                      ? IconButton(
                          tooltip: l10n.removeMember,
                          icon: Icon(AppIcons.close, color: colorScheme.error),
                          onPressed: busy
                              ? null
                              : () =>
                                    _remove(member.userId, member.displayName),
                        )
                      : null,
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: busy ? null : _leave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                ),
                child: Text(l10n.leaveHousehold),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String label,
  required String hint,
  bool upperCase = false,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      title: title,
      label: label,
      hint: hint,
      upperCase: upperCase,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.label,
    required this.hint,
    required this.upperCase,
  });

  final String title;
  final String label;
  final String hint;
  final bool upperCase;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: widget.upperCase
            ? TextCapitalization.characters
            : TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.ok)),
      ],
    );
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            action,
            style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
