// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveSession _$LiveSessionFromJson(Map<String, dynamic> json) => LiveSession(
  id: json['id'] as String,
  startedAt: DateTime.parse(json['startedAt'] as String),
  endedAt: json['endedAt'] == null
      ? null
      : DateTime.parse(json['endedAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  hosts: (json['hosts'] as List<dynamic>)
      .map((e) => LiveUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  participants: (json['participants'] as List<dynamic>)
      .map((e) => LiveUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  audience: (json['audience'] as List<dynamic>)
      .map((e) => LiveUser.fromJson(e as Map<String, dynamic>))
      .toList(),
  comments: (json['comments'] as List<dynamic>)
      .map((e) => LiveComment.fromJson(e as Map<String, dynamic>))
      .toList(),
  gifts: (json['gifts'] as List<dynamic>)
      .map((e) => LiveGift.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LiveSessionToJson(LiveSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt.toIso8601String(),
      'endedAt': instance.endedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'hosts': instance.hosts.map((e) => e.toJson()).toList(),
      'participants': instance.participants.map((e) => e.toJson()).toList(),
      'audience': instance.audience.map((e) => e.toJson()).toList(),
      'comments': instance.comments.map((e) => e.toJson()).toList(),
      'gifts': instance.gifts.map((e) => e.toJson()).toList(),
    };
