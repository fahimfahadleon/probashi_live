// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePic: json['profilePic'] as String,
      bio: json['bio'] as String?,
      coin: (json['coin'] as num).toInt(),
      diamond: (json['diamond'] as num).toInt(),
      level: (json['level'] as num).toInt(),
      vipStatus: json['vipStatus'] as bool,
      badge: json['badge'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      extra: json['extra'] as Map<String, dynamic>?,
      isBlocked: json['isBlocked'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      stats: json['stats'] == null
          ? null
          : UserStats.fromJson(json['stats'] as Map<String, dynamic>),
      relation: json['relation'] == null
          ? null
          : UserRelation.fromJson(json['relation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePic': instance.profilePic,
      'bio': instance.bio,
      'coin': instance.coin,
      'diamond': instance.diamond,
      'level': instance.level,
      'vipStatus': instance.vipStatus,
      'badge': instance.badge,
      'settings': instance.settings,
      'extra': instance.extra,
      'isBlocked': instance.isBlocked,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'stats': instance.stats,
      'relation': instance.relation,
    };

UserStats _$UserStatsFromJson(Map<String, dynamic> json) => UserStats(
      followers: (json['followers'] as num).toInt(),
      following: (json['following'] as num).toInt(),
      friends: (json['friends'] as num).toInt(),
    );

Map<String, dynamic> _$UserStatsToJson(UserStats instance) => <String, dynamic>{
      'followers': instance.followers,
      'following': instance.following,
      'friends': instance.friends,
    };

UserRelation _$UserRelationFromJson(Map<String, dynamic> json) => UserRelation(
      isFollowing: json['isFollowing'] as bool,
      isFriend: json['isFriend'] as bool,
    );

Map<String, dynamic> _$UserRelationToJson(UserRelation instance) =>
    <String, dynamic>{
      'isFollowing': instance.isFollowing,
      'isFriend': instance.isFriend,
    };
