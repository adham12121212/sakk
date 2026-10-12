import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../l10n/app_localizations.dart';

/// Where smart add reads from.
enum SmartAddSource { camera, gallery, text }

/// Asks how to smart add: a photo, a screenshot or pasted text.
Future<SmartAddSource?> showSmartAddSourceSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<SmartAddSource>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (source, icon, label) in [
              (
                SmartAddSource.gallery,
                AppIcons.gallery,
                l10n.smartAddChooseScreenshot,
              ),
              (SmartAddSource.camera, AppIcons.camera, l10n.smartAddTakePhoto),
              (SmartAddSource.text, AppIcons.chat, l10n.smartAddPasteText),
            ])
              ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(sheetContext).pop(source),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Asks for the message text (e.g. a bank SMS). Returns null if dismissed.
Future<String?> showPasteMessageSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const _PasteMessageSheet(),
  );
}

class _PasteMessageSheet extends StatefulWidget {
  const _PasteMessageSheet();

  @override
  State<_PasteMessageSheet> createState() => _PasteMessageSheetState();
}

class _PasteMessageSheetState extends State<_PasteMessageSheet> {
  final _controller = TextEditingController();
  String? _error;

  /// Same bound as the edge function: a few SMS or an email.
  static const _maxLength = 4000;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || !mounted) return;
    setState(() {
      _controller.text = text.length > _maxLength
          ? text.substring(0, _maxLength)
          : text;
      _error = null;
    });
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context)!.smartAddPasteEmpty);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      // Stay above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.smartAddPasteTitle,
                      style: textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _paste,
                    icon: const Icon(AppIcons.copy, size: 18),
                    label: Text(l10n.smartAddPasteFromClipboard),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                autofocus: true,
                minLines: 5,
                maxLines: 10,
                maxLength: _maxLength,
                keyboardType: TextInputType.multiline,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: l10n.smartAddPasteHint,
                  errorText: _error,
                ),
              ),
              Text(l10n.smartAddPrivacyNote, style: textTheme.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.smartAddRead),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
