// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveComment _$LiveCommentFromJson(Map<String, dynamic> json) => LiveComment(
  id: json['id'] as String,
  liveUser: LiveUser.fromJson(json['liveUser'] as Map<String, dynamic>),
  message: json['message'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$LiveCommentToJson(LiveComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'liveUser': instance.liveUser.toJson(),
      'message': instance.message,
      'createdAt': instance.createdAt.toIso8601String(),
    };
