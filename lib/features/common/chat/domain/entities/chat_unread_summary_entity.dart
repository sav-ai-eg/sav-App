import 'package:equatable/equatable.dart';

class ChatUnreadSummaryEntity extends Equatable {
  const ChatUnreadSummaryEntity({
    required this.totalUnreadMessages,
    required this.conversationsWithUnread,
  });

  final int totalUnreadMessages;
  final int conversationsWithUnread;

  @override
  List<Object?> get props => <Object?>[
        totalUnreadMessages,
        conversationsWithUnread,
      ];
}