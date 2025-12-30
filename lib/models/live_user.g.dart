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

Map<String, dynamic> _$LiveUserToJson(LiveUser instance) {
  final val = <String, dynamic>{
    'id': instance.id,
    'userId': instance.userId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('hostSessionId', instance.hostSessionId);
  writeNotNull('participantSessionId', instance.participantSessionId);
  writeNotNull('audienceSessionId', instance.audienceSessionId);
  val['isHost'] = instance.isHost;
  val['joinedAt'] = instance.joinedAt.toIso8601String();
  val['leftAt'] = instance.leftAt?.toIso8601String();
  val['role'] = instance.role;
  val['user'] = instance.user.toJson();
  return val;
}
