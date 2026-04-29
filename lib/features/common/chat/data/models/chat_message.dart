class ChatMessage {
  final String text;
  final bool isIncoming;
  final String senderName;
  final String senderRole;

  const ChatMessage({
    required this.text,
    required this.isIncoming,
    this.senderName = '',
    this.senderRole = '',
  });

  // Factory constructor for admin messages
  factory ChatMessage.admin({required String text}) {
    return ChatMessage(
      text: text,
      isIncoming: true,
      senderName: 'Admin',
      senderRole: 'admin',
    );
  }

  // Factory constructor for driver messages
  factory ChatMessage.driver({required String text}) {
    return ChatMessage(
      text: text,
      isIncoming: false,
      senderName: 'You',
      senderRole: 'driver',
    );
  }
}
