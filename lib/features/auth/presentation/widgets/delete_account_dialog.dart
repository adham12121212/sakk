import 'package:flutter/material.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Asks the user to type a confirmation word before deleting their account.
/// Returns `true` only if they confirmed.
Future<bool> showDeleteAccountDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => const _DeleteAccountDialog(),
  );
  return result ?? false;
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final keyword = l10n.deleteAccountKeyword;

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 36),
      title: Text(l10n.deleteAccountTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deleteAccountWarning),
          const SizedBox(height: 16),
          Text(l10n.deleteAccountTypeToConfirm(keyword), style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(hintText: keyword, border: const OutlineInputBorder()),
            onChanged: (v) => setState(() => _matches = v.trim().toLowerCase() == keyword.toLowerCase()),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel, style: TextStyle(color: AppColors.primary)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          child: Text(l10n.deleteAccountConfirm),
        ),
      ],
    );
  }
}