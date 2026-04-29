import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/common/chat/domain/entities/chat_unread_summary_entity.dart';
import 'package:sav/features/common/chat/domain/usecases/load_chat_unread_summary_use_case.dart';

part 'chat_unread_summary_state.dart';

class ChatUnreadSummaryCubit extends Cubit<ChatUnreadSummaryState> {
  ChatUnreadSummaryCubit()
      : _loadUnreadSummaryUseCase = getIt<LoadChatUnreadSummaryUseCase>(),
        super(const ChatUnreadSummaryState.initial()) {
    loadUnreadSummary();
  }

  final LoadChatUnreadSummaryUseCase _loadUnreadSummaryUseCase;

  Future<void> loadUnreadSummary() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await _loadUnreadSummaryUseCase();

    result.fold(
      (failure) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ));
      },
      (summary) {
        emit(state.copyWith(
          summary: summary,
          isLoading: false,
          errorMessage: null,
        ));
      },
    );
  }

  Future<void> refreshUnreadSummary() async {
    await loadUnreadSummary();
  }
}