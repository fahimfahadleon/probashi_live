import 'package:json_annotation/json_annotation.dart';
import 'package:probashi_live/models/user_profile.dart';

part 'user_relations_dto.g.dart';

@JsonSerializable()
class UserRelationUser {
  final String id;
  final String name;
  final String profilePic;
  final bool vipStatus;
  final UserRelation relation;

  UserRelationUser({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.vipStatus,
    required this.relation,
  });

  factory UserRelationUser.fromJson(Map<String, dynamic> json) =>
      _$UserRelationUserFromJson(json);

  Map<String, dynamic> toJson() => _$UserRelationUserToJson(this);
}


@JsonSerializable()
class UserRelationsResponse {
  final List<UserRelationUser> followers;
  final List<UserRelationUser> following;
  final List<UserRelationUser> friends;

  UserRelationsResponse({
    required this.followers,
    required this.following,
    required this.friends,
  });

  factory UserRelationsResponse.fromJson(Map<String, dynamic> json) =>
      _$UserRelationsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UserRelationsResponseToJson(this);
}
