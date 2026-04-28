import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class LoadChatMessagesUseCase {
  const LoadChatMessagesUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, List<ChatMessageEntity>>> call({
    required int conversationId,
    int page = 1,
    int pageSize = 20,
  }) {
    return _repository.loadMessages(
      conversationId: conversationId,
      page: page,
      pageSize: pageSize,
    );
  }
}