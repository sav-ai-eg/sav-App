import 'package:equatable/equatable.dart';

class ChatReadReceiptEntity extends Equatable {
  const ChatReadReceiptEntity({
    required this.conversationId,
    required this.lastReadMessageId,
    required this.lastReadAt,
    required this.unreadCount,
  });

  final int conversationId;
  final int? lastReadMessageId;
  final DateTime? lastReadAt;
  final int unreadCount;

  @override
  List<Object?> get props => <Object?>[
        conversationId,
        lastReadMessageId,
        lastReadAt,
        unreadCount,
      ];
}
