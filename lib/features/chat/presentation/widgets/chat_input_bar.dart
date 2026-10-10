import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({super.key, required this.onSend, required this.isSending});

  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isSending) return;
    widget.onSend(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        // Floating white pill: text field plus a round gradient send button.
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 4, 4),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: context.palette.cardShadow,
            border: Theme.of(context).brightness == Brightness.dark
                ? Border.all(color: colorScheme.outline)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: l10n.askaboutaproductorwarranty,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 44px visible circle inside a 48×48 labelled tap area.
              Tooltip(
                message: l10n.sendMessage,
                excludeFromSemantics: true,
                child: Semantics(
                  button: true,
                  enabled: !widget.isSending,
                  label: l10n.sendMessage,
                  excludeSemantics: true,
                  child: InkResponse(
                    onTap: widget.isSending ? null : _submit,
                    radius: 26,
                    child: SizedBox.square(
                      dimension: 48,
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: widget.isSending ? 0.5 : 1,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF3D7BFF), Color(0xFF5B3DF5)],
                              ),
                            ),
                            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}