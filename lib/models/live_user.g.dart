// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveUser _$LiveUserFromJson(Map<String, dynamic> json) => LiveUser(
  id: json['id'] as String,
  userId: json['userId'] as String,
  hostSessionId: json['hostSessionId'] as String?,
  participantSessionId: json['participantSessionId'] as String?,
  audienceSessionId: json['audienceSessionId'] as String?,
  isHost: json['isHost'] as bool,
  joinedAt: DateTime.parse(json['joinedAt'] as String),
  leftAt: json['leftAt'] == null
      ? null
      : DateTime.parse(json['leftAt'] as String),
  role: json['role'] as String,
  user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LiveUserToJson(LiveUser instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  if (instance.hostSessionId case final value?) 'hostSessionId': value,
  if (instance.participantSessionId case final value?)
    'participantSessionId': value,
  if (instance.audienceSessionId case final value?) 'audienceSessionId': value,
  'isHost': instance.isHost,
  'joinedAt': instance.joinedAt.toIso8601String(),
  'leftAt': instance.leftAt?.toIso8601String(),
  'role': instance.role,
  'user': instance.user.toJson(),
};
