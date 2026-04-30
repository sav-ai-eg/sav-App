import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/core/util/routing/routes.dart';
import 'package:sav/features/auth/presentation/cubit/login_cubit.dart';
import 'package:sav/features/auth/presentation/views/login_view.dart';
import 'package:sav/features/common/bottom_nav/presentation/cubit/bottom_nav_cubit.dart';
import 'package:sav/features/common/bottom_nav/presentation/views/bottom_nav_view.dart';
import 'package:sav/features/common/chat/presentation/cubit/feedback_chat_cubit.dart';
import 'package:sav/features/common/chat/presentation/cubit/chat_conversations_cubit.dart';
import 'package:sav/features/common/chat/presentation/views/chat_conversations_view.dart';
import 'package:sav/features/common/chat/presentation/views/feedback_chat_view.dart';
import 'package:sav/features/emergency/presentation/views/emergency_view.dart';
import 'package:sav/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:sav/features/splash/presentation/views/splash_view.dart';

class AppRouter {
  Route? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.splashView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<SplashCubit>(),
            child: const SplashView(),
          ),
        );

      case Routes.loginView:
      case Routes.driverDataView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<LoginCubit>(),
            child: const LoginView(),
          ),
        );

      case Routes.bottomNavView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => BottomNavCubit(),
            child: const BottomNavView(),
          ),
        );

      case Routes.emergencyView:
        return MaterialPageRoute(builder: (_) => const EmergencyView());

      case Routes.feedbackChatView:
        final arguments = settings.arguments;
        final conversationId = arguments is int
            ? arguments
            : arguments is Map<String, dynamic>
            ? arguments['conversationId'] as int?
            : null;

        if (conversationId != null) {
          return MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) =>
                  FeedbackChatCubit(initialConversationId: conversationId),
              child: const FeedbackChatView(),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => FeedbackChatCubit.full(),
            child: const FeedbackChatView(),
          ),
        );

      case Routes.feedbackChatPromptView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => FeedbackChatCubit(),
            child: const FeedbackChatView(),
          ),
        );

      case Routes.chatConversationsView:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => ChatConversationsCubit(),
            child: const ChatConversationsView(),
          ),
        );

      case Routes.notificationView:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text('Notifications will be available soon.'),
              ),
            ),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
