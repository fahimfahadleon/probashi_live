class ChatInboxUser {
  final Map<String, dynamic> user;
  final String latestMessage;
  final String messageId;
  final DateTime createdAt;
  final bool isSender;


  ChatInboxUser({
    required this.user,
    required this.latestMessage,
    required this.messageId,
    required this.createdAt,
    required this.isSender,
  });

  factory ChatInboxUser.fromJson(Map<String, dynamic> json) {
    return ChatInboxUser(
      user: json['user'],
      latestMessage: json['latestMessage'],
      messageId: json['messageId'],
      createdAt: DateTime.parse(json['createdAt']),
      isSender: json['isSender'],
    );
  }
}
