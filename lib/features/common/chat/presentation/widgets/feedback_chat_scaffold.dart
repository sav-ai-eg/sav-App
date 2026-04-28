import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/constants/app_colors.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/common/chat/data/models/chat_message.dart';
import 'package:sav/features/common/chat/presentation/widgets/feedback_chat_sheet.dart';

class FeedbackChatScaffold extends StatefulWidget {
  final List<ChatMessage> messages;

  const FeedbackChatScaffold({super.key, required this.messages});

  @override
  State<FeedbackChatScaffold> createState() => _FeedbackChatScaffoldState();
}

class _FeedbackChatScaffoldState extends State<FeedbackChatScaffold> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setBottomNavHidden(true);
    });
  }

  @override
  void dispose() {
    _setBottomNavHidden(false);
    _controller.dispose();
    super.dispose();
  }

  BottomNavCubit? _tryBottomNavCubit() {
    try {
      return context.read<BottomNavCubit>();
    } catch (_) {
      return null;
    }
  }

  void _setBottomNavHidden(bool hidden) {
    if (!mounted) {
      return;
    }
    _tryBottomNavCubit()?.setHideNavBar(hidden);
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: Container(color: AppColors.scaffoldColor)),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(
                color: AppColors.darkNavy.withValues(alpha: 0.4),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: FeedbackChatSheet(
                messages: widget.messages,
                controller: _controller,
                onSend: _handleSend,
                onClose: _handleClose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
