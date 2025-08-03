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
    );

Map<String, dynamic> _$FriendUserModelToJson(FriendUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePic': instance.profilePic,
      'vipStatus': instance.vipStatus,
      'level': instance.level,
    };
