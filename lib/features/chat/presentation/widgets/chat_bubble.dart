import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';

/// A user message that failed to send gets a "tap to retry" line under it.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.onRetry});

  final ChatMessageEntity message;

  /// Set only on the failed message; shows the retry line and runs on tap.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;

    final bubble = Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) ...[
          _AssistantAvatar(),
          SizedBox(width: 8.w),
        ],
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.s16, vertical: AppSizes.s12),
            decoration: BoxDecoration(
              color: isUser ? AppColors.primary : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.lg),
                topRight: Radius.circular(AppRadius.lg),
                bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4.r),
                bottomRight: Radius.circular(isUser ? 4.r : AppRadius.lg),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: isUser ? AppColors.white : colorScheme.onSurface,
              ),
            ),
          ),
        ),
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

class _AssistantAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.auto_awesome_rounded, size: 14.sp, color: AppColors.primary),
    );
  }
}