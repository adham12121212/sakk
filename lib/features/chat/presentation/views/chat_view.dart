import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_error.dart';
import '../../../../core/constant/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pro/domain/pro_limit.dart';
import '../../../pro/presentation/pro_actions.dart';
import '../../../pro/presentation/widgets/quota_hint.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_empty_state.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_typing_indicator.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatCubit>().loadHistoryIfNeeded();
  }

  /// Today's free messages are used up: the paywall instead of a refused send.
  bool _canSend() => ProActions.ensureCanUse(context, QuotaType.chat);

  void _send(String text) {
    if (_canSend()) context.read<ChatCubit>().sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n!.aIAssistant),
          surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listener: (context, state) {
          _scrollToBottom();
          if (state.error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                content: Text(state.error == NetworkFailure.noConnectionMessage
                    ? l10n.chatNeedsInternet
                    : userFacingError(l10n, state.error)),
                backgroundColor: AppColors.error,
              ));
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? ChatEmptyState(
                  l10n: l10n,
                  onSuggestionTap: _send,
                )
                    : ListView.separated(
                  controller: _scrollController,
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  itemCount: state.messages.length + (state.isSending ? 1 : 0),
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return const ChatTypingIndicator();
                    }
                    final message = state.messages[index];
                    return ChatBubble(
                      message: message,
                      onRetry: message.id == state.failedMessageId && !state.isSending
                          ? context.read<ChatCubit>().retryFailedMessage
                          : null,
                    );
                  },
                ),
              ),
              const QuotaHint(type: QuotaType.chat),
              ChatInputBar(
                isSending: state.isSending,
                canSend: _canSend,
                onSend: (text) => context.read<ChatCubit>().sendMessage(text),
              ),
            ],
          );
        },
      ),
    );
  }
}