// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_gift.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveGift _$LiveGiftFromJson(Map<String, dynamic> json) => LiveGift(
  id: json['id'] as String,
  fromUser: LiveUser.fromJson(json['fromUser'] as Map<String, dynamic>),
  toUser: LiveUser.fromJson(json['toUser'] as Map<String, dynamic>),
  giftType: json['giftType'] as String,
  diamondCount: (json['diamondCount'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$LiveGiftToJson(LiveGift instance) => <String, dynamic>{
  'id': instance.id,
  'fromUser': instance.fromUser.toJson(),
  'toUser': instance.toUser.toJson(),
  'giftType': instance.giftType,
  'diamondCount': instance.diamondCount,
  'createdAt': instance.createdAt.toIso8601String(),
};
