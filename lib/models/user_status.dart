import 'package:json_annotation/json_annotation.dart';

part 'user_status.g.dart';

@JsonSerializable()
class UserStats {
  final int followers;
  final int following;
  final int friends;

  UserStats({
    required this.followers,
    required this.following,
    required this.friends,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);

  Map<String, dynamic> toJson() => _$UserStatsToJson(this);
}