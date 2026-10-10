import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import 'ai_avatar.dart';
import 'dots.dart';

/// "Assistant is typing": AI avatar plus a small white bubble of pulsing dots.
class ChatTypingIndicator extends StatelessWidget {
  const ChatTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const AiAvatar(),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadiusDirectional.only(
              topStart: Radius.circular(20),
              topEnd: Radius.circular(20),
              bottomStart: Radius.circular(6),
              bottomEnd: Radius.circular(20),
            ),
            boxShadow: context.palette.cardShadow,
            border: isDark ? Border.all(color: colorScheme.outline) : null,
          ),
          child: const SizedBox(width: 32, height: 12, child: Dots()),
        ),
      ],
    );
  }
}
