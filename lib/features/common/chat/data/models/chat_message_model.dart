import 'package:sav/features/auth/data/models/auth_user_model.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.sender,
    required super.text,
    required super.isOwn,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatMessageModel.fromBackendMap(Map<String, dynamic> map) {
    final senderPayload = map['sender'];
    final sender = senderPayload is Map<String, dynamic>
        ? AuthUserModel.fromMap(senderPayload)
        : null;

    return ChatMessageModel(
      id: _toInt(map['id']),
      conversationId: _toInt(map['conversation_id']),
      senderId: _toInt(map['sender_id']),
      sender: sender,
      text: (map['text'] ?? '').toString(),
      isOwn: _toBool(map['is_own']),
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    return (value ?? '').toString().toLowerCase() == 'true';
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}