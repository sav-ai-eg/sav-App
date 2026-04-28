import 'package:dartz/dartz.dart';
import 'package:sav/core/errors/failures.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_read_receipt_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_unread_summary_entity.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatConversationEntity>> bootstrapConversation({
    int? driverId,
  });

  Future<Either<Failure, List<ChatConversationEntity>>> loadConversations({
    int page,
    int pageSize,
    String? search,
  });

  Future<Either<Failure, List<ChatMessageEntity>>> loadMessages({
    required int conversationId,
    int page,
    int pageSize,
  });

  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int conversationId,
    required String text,
  });

  Future<Either<Failure, ChatReadReceiptEntity>> markConversationRead({
    required int conversationId,
    int? messageId,
  });

  Future<Either<Failure, ChatUnreadSummaryEntity>> loadUnreadSummary();
}