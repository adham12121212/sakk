import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../l10n/app_localizations.dart';
import 'ai_avatar.dart';

/// User messages: brand-gradient bubble at the end. Assistant replies: white
/// card at the start next to the AI avatar, selectable so it can be copied.
/// Corners are directional, so the "tail" sits on the right side in RTL too.
/// A user message that failed to send gets a "tap to retry" line under it.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessageEntity message;

  /// Set only on the failed message; shows the retry line and runs on tap.
  final VoidCallback? onRetry;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D7BFF), Color(0xFF5B3DF5)],
  );

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const r = Radius.circular(20);
    const tail = Radius.circular(6);

    // Each message keeps its own direction: an English reply inside the
    // Arabic UI must not have its punctuation flipped, and vice versa.
    final textDirection = Bidi.detectRtlDirectionality(message.content) ? TextDirection.rtl : TextDirection.ltr;

    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.5,
          color: isUser ? Colors.white : colorScheme.onSurface,
        );

    final bubble = Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          const AiAvatar(),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isUser ? _gradient : null,
              color: isUser ? null : colorScheme.surface,
              borderRadius: BorderRadiusDirectional.only(
                topStart: r,
                topEnd: r,
                bottomStart: isUser ? r : tail,
                bottomEnd: isUser ? tail : r,
              ),
              boxShadow: isUser ? null : context.palette.cardShadow,
              border: !isUser && isDark ? Border.all(color: colorScheme.outline) : null,
            ),
            child: isUser
                ? Text(message.content, style: textStyle, textDirection: textDirection)
                : SelectableText(message.content, style: textStyle, textDirection: textDirection),
          ),
        ),
        if (isUser) const SizedBox(width: 4),
      ],
    );

    if (onRetry == null) return bubble;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bubble,
        InkWell(
          onTap: onRetry,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: colorScheme.error),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.messageNotSent,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
