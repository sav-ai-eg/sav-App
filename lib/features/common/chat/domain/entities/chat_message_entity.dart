import 'package:equatable/equatable.dart';
import 'package:sav/features/auth/domain/entities/auth_user_entity.dart';

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.sender,
    required this.text,
    required this.isOwn,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final AuthUserEntity? sender;
  final String text;
  final bool isOwn;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => <Object?>[
        id,
        conversationId,
        senderId,
        sender,
        text,
        isOwn,
        createdAt,
        updatedAt,
      ];
}
