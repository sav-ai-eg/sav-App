import 'package:flutter/material.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_sheet.dart';

class FeedbackChatScaffold extends StatefulWidget {
  final List<ChatMessage> messages;
  final Future<bool> Function(String text) onSendText;
  final VoidCallback onRetry;
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;

  const FeedbackChatScaffold({
    super.key,
    required this.messages,
    required this.onSendText,
    required this.onRetry,
    required this.isLoading,
    required this.isSending,
    this.errorMessage,
  });

  @override
  State<FeedbackChatScaffold> createState() => _FeedbackChatScaffoldState();
}

class _FeedbackChatScaffoldState extends State<FeedbackChatScaffold> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final didSend = await widget.onSendText(text);
    if (!mounted || !didSend) {
      return;
    }

    _controller.clear();
  }

  void _handleClose() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FeedbackChatSheet(
          messages: widget.messages,
          controller: _controller,
          onSend: _handleSend,
          onClose: _handleClose,
          onRetry: widget.onRetry,
          isLoading: widget.isLoading,
          isSending: widget.isSending,
          errorMessage: widget.errorMessage,
        ),
      ),
    );
  }
}
