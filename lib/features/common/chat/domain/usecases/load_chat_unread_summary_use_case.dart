import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_unread_summary_entity.dart';
import 'package:sav/features/common/chat/domain/repositories/chat_repository.dart';

@injectable
class LoadChatUnreadSummaryUseCase {
  const LoadChatUnreadSummaryUseCase(this._repository);

  final ChatRepository _repository;

  Future<Either<Failure, ChatUnreadSummaryEntity>> call() {
    return _repository.loadUnreadSummary();
  }
}