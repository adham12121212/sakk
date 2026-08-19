import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sakk/features/chat/domain/entities/chat_message_entity.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../core/util/app_radius.dart';
import '../../../../core/util/app_sizes.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessageEntity message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Row(
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
              color: isUser ? AppColors.primary : Colors.grey.shade100,
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
                color: isUser ? AppColors.white : AppColors.black,
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