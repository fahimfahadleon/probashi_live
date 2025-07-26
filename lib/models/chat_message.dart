// models/chat_message.dart
class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'],
    senderId: json['senderId'],
    receiverId: json['receiverId'],
    content: json['content'],
    createdAt: DateTime.parse(json['createdAt']),
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

}
