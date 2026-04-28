import 'package:sav/features/common/chat/domain/entities/chat_unread_summary_entity.dart';

class ChatUnreadSummaryModel extends ChatUnreadSummaryEntity {
  const ChatUnreadSummaryModel({
    required super.totalUnreadMessages,
    required super.conversationsWithUnread,
  });

  factory ChatUnreadSummaryModel.fromBackendMap(Map<String, dynamic> map) {
    return ChatUnreadSummaryModel(
      totalUnreadMessages: _toInt(map['total_unread_messages']),
      conversationsWithUnread: _toInt(map['conversations_with_unread']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}