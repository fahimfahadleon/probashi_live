// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
