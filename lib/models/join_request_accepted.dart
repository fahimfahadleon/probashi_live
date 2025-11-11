class JoinRequestAccepted {
  final String userId;
  final String sessionId;
  final String fromUser;

  JoinRequestAccepted({
    required this.userId,
    required this.sessionId,
    required this.fromUser,
  });

  factory JoinRequestAccepted.fromJson(Map<String, dynamic> json) {
    return JoinRequestAccepted(
      userId: json['userId'].toString(),
      sessionId: json['sessionId'].toString(),
      fromUser: json['fromUser'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'sessionId': sessionId,
      'fromUser': fromUser,
    };
  }
}
