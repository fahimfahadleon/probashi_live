import 'package:json_annotation/json_annotation.dart';
import 'live_user.dart';
import 'live_comment.dart';
import 'live_gift.dart';

part 'live_session.g.dart';

@JsonSerializable(explicitToJson: true)
class LiveSession {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  final List<LiveUser> hosts;
  final List<LiveUser> participants;
  final List<LiveUser> audience;

  final List<LiveComment> comments;
  final List<LiveGift> gifts;

  LiveSession({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.hosts,
    required this.participants,
    required this.audience,
    required this.comments,
    required this.gifts,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) =>
      _$LiveSessionFromJson(json);

  Map<String, dynamic> toJson() => _$LiveSessionToJson(this);
}
