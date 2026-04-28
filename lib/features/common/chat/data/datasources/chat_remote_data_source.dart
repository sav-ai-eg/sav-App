import 'package:sav/features/common/chat/data/models/chat_conversation_model.dart';
import 'package:sav/features/common/chat/data/models/chat_message_model.dart';
import 'package:sav/features/common/chat/data/models/chat_read_receipt_model.dart';
import 'package:sav/features/common/chat/data/models/chat_unread_summary_model.dart';

abstract class ChatRemoteDataSource {
  Future<ChatConversationModel> bootstrapConversation({int? driverId});

  Future<List<ChatConversationModel>> loadConversations({
    int page,
    int pageSize,
    String? search,
  });

  Future<List<ChatMessageModel>> loadMessages({
    required int conversationId,
    int page,
    int pageSize,
  });

  Future<ChatMessageModel> sendMessage({
    required int conversationId,
    required String text,
  });

  Future<ChatReadReceiptModel> markConversationRead({
    required int conversationId,
    int? messageId,
  });

  Future<ChatUnreadSummaryModel> loadUnreadSummary();
}