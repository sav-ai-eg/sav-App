import 'package:sav/features/auth/data/models/auth_user_model.dart';
import 'package:sav/features/common/chat/data/models/chat_message_model.dart';
import 'package:sav/features/common/chat/domain/entities/chat_conversation_entity.dart';

class ChatConversationModel extends ChatConversationEntity {
  const ChatConversationModel({
    required super.id,
    required super.driverId,
    required super.driver,
    required super.unreadCount,
    required super.lastMessage,
    required super.lastMessageAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatConversationModel.fromBackendMap(Map<String, dynamic> map) {
    final driverPayload = map['driver'];
    final lastMessagePayload = map['last_message'];

    return ChatConversationModel(
      id: _toInt(map['id']),
      driverId: _toInt(map['driver_id']),
      driver: driverPayload is Map<String, dynamic>
          ? AuthUserModel.fromMap(driverPayload)
          : null,
      unreadCount: _toInt(map['unread_count']),
      lastMessage: lastMessagePayload is Map<String, dynamic>
          ? ChatMessageModel.fromBackendMap(lastMessagePayload)
          : null,
      lastMessageAt: _toDateTime(map['last_message_at']),
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

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}