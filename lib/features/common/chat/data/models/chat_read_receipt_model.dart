import 'package:sav/features/common/chat/domain/entities/chat_read_receipt_entity.dart';

class ChatReadReceiptModel extends ChatReadReceiptEntity {
  const ChatReadReceiptModel({
    required super.conversationId,
    required super.lastReadMessageId,
    required super.lastReadAt,
    required super.unreadCount,
  });

  factory ChatReadReceiptModel.fromBackendMap(Map<String, dynamic> map) {
    return ChatReadReceiptModel(
      conversationId: _toInt(map['conversation_id']),
      lastReadMessageId: _toNullableInt(map['last_read_message_id']),
      lastReadAt: _toDateTime(map['last_read_at']),
      unreadCount: _toInt(map['unread_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }

    return int.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}