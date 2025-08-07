import 'package:json_annotation/json_annotation.dart';

part 'friend_user_model.g.dart';

@JsonSerializable()
class FriendUserModel {
  final String id;
  final String name;
  final String profilePic;
  final bool vipStatus;
  final Map<String,dynamic> settings;
  final int level;

  FriendUserModel({
    required this.id,
    required this.name,
    required this.profilePic,
    required this.vipStatus,
    required this.level,
    required this. settings
  });

  factory FriendUserModel.fromJson(Map<String, dynamic> json) =>
      _$FriendUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendUserModelToJson(this);
}