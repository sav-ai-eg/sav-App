import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class LoadChatConversationsUseCase {
  LoadChatConversationsUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<ChatConversationEntity>>> call({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    return await _repository.loadConversations(
      page: page,
      pageSize: pageSize,
      search: search,
    );
  }
}