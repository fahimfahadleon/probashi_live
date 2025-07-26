import 'package:probashi_live/models/user_profile.dart';

class ChatInboxEntry {
  final UserProfile user;
  final String latestMessage;
  final String messageId;
  final DateTime createdAt;
  final bool isSender;

  ChatInboxEntry({
    required this.user,
    required this.latestMessage,
    required this.messageId,
    required this.createdAt,
    required this.isSender,
  });

  factory ChatInboxEntry.fromJson(Map<String, dynamic> json) {
    return ChatInboxEntry(
      user: UserProfile.fromJson(json['user']),
      latestMessage: json['latestMessage'],
      messageId: json['messageId'],
      createdAt: DateTime.parse(json['createdAt']),
      isSender: json['isSender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'latestMessage': latestMessage,
      'messageId': messageId,
      'createdAt': createdAt.toIso8601String(),
      'isSender': isSender,
    };
  }
}
