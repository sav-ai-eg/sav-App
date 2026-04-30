class ChatMessage {
  final int? id;
  final String text;
  final bool isIncoming;
  final String senderName;
  final String senderRole;
  final DateTime? createdAt;

  const ChatMessage({
    this.id,
    required this.text,
    required this.isIncoming,
    this.senderName = '',
    this.senderRole = '',
    this.createdAt,
  });

  String get stableKey {
    final messageId = id;
    if (messageId != null && messageId > 0) {
      return 'chat-message-$messageId';
    }

    final timestamp = createdAt?.microsecondsSinceEpoch;
    final direction = isIncoming ? 'incoming' : 'outgoing';
    return '$direction-${timestamp ?? text.hashCode}-${text.hashCode}';
  }

  factory ChatMessage.admin({
    int? id,
    required String text,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isIncoming: true,
      senderName: 'Admin',
      senderRole: 'admin',
      createdAt: createdAt,
    );
  }

  factory ChatMessage.driver({
    int? id,
    required String text,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id,
      text: text,
      isIncoming: false,
      senderName: 'You',
      senderRole: 'driver',
      createdAt: createdAt,
    );
  }
}
