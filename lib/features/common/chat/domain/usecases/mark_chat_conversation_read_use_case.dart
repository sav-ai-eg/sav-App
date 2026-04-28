import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_read_receipt_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class MarkChatConversationReadUseCase {
  const MarkChatConversationReadUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, ChatReadReceiptEntity>> call({
    required int conversationId,
    int? messageId,
  }) {
    return _repository.markConversationRead(
      conversationId: conversationId,
      messageId: messageId,
    );
  }
}