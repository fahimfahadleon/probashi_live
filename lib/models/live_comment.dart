import 'package:json_annotation/json_annotation.dart';
import 'live_user.dart';

part 'live_comment.g.dart';

@JsonSerializable(explicitToJson: true)
class LiveComment {
  final String id;
  final LiveUser liveUser;
  final String message;
  final DateTime createdAt;

  LiveComment({
    required this.id,
    required this.liveUser,
    required this.message,
    required this.createdAt,
  });

  factory LiveComment.fromJson(Map<String, dynamic> json) =>
      _$LiveCommentFromJson(json);

  Map<String, dynamic> toJson() => _$LiveCommentToJson(this);
}
