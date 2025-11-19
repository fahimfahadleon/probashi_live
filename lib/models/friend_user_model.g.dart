// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendUserModel _$FriendUserModelFromJson(Map<String, dynamic> json) =>
    FriendUserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePic: json['profilePic'] as String,
      vipStatus: json['vipStatus'] as bool,
      level: (json['level'] as num).toInt(),
      settings: json['settings'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$FriendUserModelToJson(FriendUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePic': instance.profilePic,
      'vipStatus': instance.vipStatus,
      'settings': instance.settings,
      'level': instance.level,
    };

CreateReportDto _$CreateReportDtoFromJson(Map<String, dynamic> json) =>
    CreateReportDto(
      email: json['email'] as String,
      reason: json['reason'] as String,
      targetId: json['targetId'] as String?,
    );

Map<String, dynamic> _$CreateReportDtoToJson(CreateReportDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'reason': instance.reason,
      'targetId': instance.targetId,
    };
