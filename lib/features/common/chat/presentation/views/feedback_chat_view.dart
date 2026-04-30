import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/features/common/chat/presentation/cubit/feedback_chat_cubit.dart';
import 'package:sav/features/common/chat/presentation/cubit/feedback_chat_state.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_scaffold.dart';

class FeedbackChatView extends StatelessWidget {
  const FeedbackChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FeedbackChatCubit, FeedbackChatState>(
      listener: (context, state) {
        final errorMessage = state.errorMessage;
        if (errorMessage != null &&
            errorMessage.isNotEmpty &&
            state.status != FeedbackChatStatus.error) {
          ScaffoldMessenger.of(context)
            ..removeCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      },
      builder: (context, state) {
        return FeedbackChatScaffold(
          messages: state.messages,
          onSendText: context.read<FeedbackChatCubit>().sendText,
          onRetry: context.read<FeedbackChatCubit>().retryOpen,
          isLoading: state.isLoading,
          isSending: state.isSending,
          errorMessage: state.status == FeedbackChatStatus.error
              ? state.errorMessage
              : null,
        );
      },
    );
  }
}
