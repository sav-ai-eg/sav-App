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
    super.chatPartner,
  });

  factory ChatConversationModel.fromBackendMap(Map<String, dynamic> map) {
    final driverPayload = map['driver'];
    final lastMessagePayload = map['last_message'];
    final chatPartnerPayload = map['chat_partner'] ?? map['chatPartner'];

    final driver = driverPayload is Map<String, dynamic>
        ? AuthUserModel.fromMap(driverPayload)
        : driverPayload is Map
        ? AuthUserModel.fromMap(Map<String, dynamic>.from(driverPayload))
        : null;

    final chatPartner = chatPartnerPayload is Map<String, dynamic>
        ? AuthUserModel.fromMap(chatPartnerPayload)
        : chatPartnerPayload is Map
        ? AuthUserModel.fromMap(Map<String, dynamic>.from(chatPartnerPayload))
        : null;

    return ChatConversationModel(
      id: _toInt(map['id']),
      driverId: _toInt(
        map['driver_id'] ??
            map['driverId'] ??
            (driverPayload is Map ? driverPayload['id'] : driverPayload),
      ),
      driver: driver,
      chatPartner: chatPartner,
      unreadCount: _toInt(map['unread_count'] ?? map['unreadCount']),
      lastMessage: lastMessagePayload is Map<String, dynamic>
          ? ChatMessageModel.fromBackendMap(lastMessagePayload)
          : lastMessagePayload is Map
          ? ChatMessageModel.fromBackendMap(
              Map<String, dynamic>.from(lastMessagePayload),
            )
          : null,
      lastMessageAt: _toDateTime(
        map['last_message_at'] ??
            map['lastMessageAt'] ??
            (lastMessagePayload is Map
                ? lastMessagePayload['created_at']
                : null),
      ),
      createdAt: _toDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _toDateTime(map['updated_at'] ?? map['updatedAt']),
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
