import 'package:json_annotation/json_annotation.dart';
import 'user_profile.dart';

part 'live_user.g.dart';

@JsonSerializable(explicitToJson: true)
class LiveUser {
  final String id;
  final String userId;

  @JsonKey(name: 'hostSessionId', includeIfNull: false)
  final String? hostSessionId;

  @JsonKey(name: 'participantSessionId', includeIfNull: false)
  final String? participantSessionId;

  @JsonKey(name: 'audienceSessionId', includeIfNull: false)
  final String? audienceSessionId;

  final bool isHost;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String role;

  final UserProfile user;  // nested UserProfile object

  LiveUser({
    required this.id,
    required this.userId,
    this.hostSessionId,
    this.participantSessionId,
    this.audienceSessionId,
    required this.isHost,
    required this.joinedAt,
    this.leftAt,
    required this.role,
    required this.user,
  });

  factory LiveUser.fromJson(Map<String, dynamic> json) =>
      _$LiveUserFromJson(json);

  Map<String, dynamic> toJson() => _$LiveUserToJson(this);
}
