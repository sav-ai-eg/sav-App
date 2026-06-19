import 'package:equatable/equatable.dart';
import 'package:sav/features/auth/domain/entities/auth_user_entity.dart';
import 'package:sav/features/common/chat/domain/entities/chat_message_entity.dart';

class ChatConversationEntity extends Equatable {
  const ChatConversationEntity({
    required this.id,
    required this.driverId,
    required this.driver,
    required this.unreadCount,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    this.chatPartner,
  });

  final int id;
  final int driverId;
  final AuthUserEntity? driver;
  final int unreadCount;
  final ChatMessageEntity? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final AuthUserEntity? chatPartner;

  @override
  List<Object?> get props => <Object?>[
        id,
        driverId,
        driver,
        unreadCount,
        lastMessage,
        lastMessageAt,
        createdAt,
        updatedAt,
        chatPartner,
      ];
}
