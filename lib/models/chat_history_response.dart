import 'chat_message.dart';

class ChatHistoryResponse {
  final String userId;
  final String otherUserId;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<ChatMessage> messages;

  ChatHistoryResponse({
    required this.userId,
    required this.otherUserId,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.messages,
  });

  factory ChatHistoryResponse.fromJson(Map<String, dynamic> json) {
    return ChatHistoryResponse(
      userId: json['userId'],
      otherUserId: json['otherUserId'],
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      totalPages: json['totalPages'],
      messages: (json['messages'] as List<dynamic>)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'otherUserId': otherUserId,
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }
}
