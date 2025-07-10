import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String name;
  final String profilePic;
  final String? bio;
  final int coin;
  final int diamond;
  final int level;
  final bool vipStatus;
  final String? badge;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? extra;
  final DateTime createdAt;

  final UserStats stats;
  final UserRelation relation;

  UserProfile({
    required this.id,
    required this.name,
    required this.profilePic,
    this.bio,
    required this.coin,
    required this.diamond,
    required this.level,
    required this.vipStatus,
    this.badge,
    this.settings,
    this.extra,
    required this.createdAt,
    required this.stats,
    required this.relation,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
}

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

@JsonSerializable()
class UserRelation {
  final bool isFollowing;
  final bool isFriend;

  UserRelation({
    required this.isFollowing,
    required this.isFriend,
  });

  factory UserRelation.fromJson(Map<String, dynamic> json) =>
      _$UserRelationFromJson(json);

  Map<String, dynamic> toJson() => _$UserRelationToJson(this);
}