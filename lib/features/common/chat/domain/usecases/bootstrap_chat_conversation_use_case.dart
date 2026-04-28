import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class BootstrapChatConversationUseCase {
  const BootstrapChatConversationUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, ChatConversationEntity>> call({int? driverId}) {
    return _repository.bootstrapConversation(driverId: driverId);
  }
}