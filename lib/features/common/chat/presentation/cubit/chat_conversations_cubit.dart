import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sav/core/di/injection.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';
import 'package:sav/features/common/chat/domain/usecases/load_chat_conversations_use_case.dart';

part 'chat_conversations_state.dart';

class ChatConversationsCubit extends Cubit<ChatConversationsState> {
  ChatConversationsCubit()
    : _loadConversationsUseCase = getIt<LoadChatConversationsUseCase>(),
      super(const ChatConversationsState.initial());

  final LoadChatConversationsUseCase _loadConversationsUseCase;

  Future<void> loadConversations({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, clearErrorMessage: true));

    final result = await _loadConversationsUseCase(
      page: page,
      pageSize: pageSize,
      search: search,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
      (conversations) {
        final isFirstPage = page == 1;
        final currentConversations = isFirstPage
            ? <ChatConversationEntity>[]
            : List<ChatConversationEntity>.of(state.conversations);
        currentConversations.addAll(conversations);

        emit(
          state.copyWith(
            conversations: currentConversations,
            isLoading: false,
            hasMore: conversations.length == pageSize,
            currentPage: page,
            clearErrorMessage: true,
          ),
        );
      },
    );
  }

  Future<void> refreshConversations({String? search}) async {
    emit(
      state.copyWith(
        conversations: [],
        currentPage: 0,
        hasMore: true,
        clearErrorMessage: true,
      ),
    );
    await loadConversations(search: search);
  }

  Future<void> loadMoreConversations({String? search}) async {
    if (!state.hasMore || state.isLoading) return;
    await loadConversations(page: state.currentPage + 1, search: search);
  }
}
