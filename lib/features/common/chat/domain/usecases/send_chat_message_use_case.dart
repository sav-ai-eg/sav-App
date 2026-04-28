import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class SendChatMessageUseCase {
  const SendChatMessageUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, ChatMessageEntity>> call({
    required int conversationId,
    required String text,
  }) {
    return _repository.sendMessage(
      conversationId: conversationId,
      text: text,
    );
  }
}