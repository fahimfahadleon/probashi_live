// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_relations_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRelationUser _$UserRelationUserFromJson(Map<String, dynamic> json) =>
    UserRelationUser(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePic: json['profilePic'] as String,
      vipStatus: json['vipStatus'] as bool,
      relation: UserRelation.fromJson(json['relation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UserRelationUserToJson(UserRelationUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'profilePic': instance.profilePic,
      'vipStatus': instance.vipStatus,
      'relation': instance.relation,
    };

UserRelationsResponse _$UserRelationsResponseFromJson(
        Map<String, dynamic> json) =>
    UserRelationsResponse(
      followers: (json['followers'] as List<dynamic>)
          .map((e) => UserRelationUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      following: (json['following'] as List<dynamic>)
          .map((e) => UserRelationUser.fromJson(e as Map<String, dynamic>))
          .toList(),
      friends: (json['friends'] as List<dynamic>)
          .map((e) => UserRelationUser.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserRelationsResponseToJson(
        UserRelationsResponse instance) =>
    <String, dynamic>{
      'followers': instance.followers,
      'following': instance.following,
      'friends': instance.friends,
    };
