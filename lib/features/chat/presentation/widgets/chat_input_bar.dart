import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';

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
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: 120.h),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Ask about a product or warranty…',
                    isDense: true,
                  ),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            InkWell(
              onTap: widget.isSending ? null : _submit,
              customBorder: const CircleBorder(),
              child: Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: widget.isSending
                      ? AppColors.primary.withOpacity(0.5)
                      : AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_upward_rounded, color: AppColors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}