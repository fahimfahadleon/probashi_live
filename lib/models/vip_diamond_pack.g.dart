// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vip_diamond_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VipPackDto _$VipPackDtoFromJson(Map<String, dynamic> json) => VipPackDto(
      id: json['id'] as String,
      diamonds: (json['diamonds'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$VipPackDtoToJson(VipPackDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'diamonds': instance.diamonds,
      'price': instance.price,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ProductVipPackDto _$ProductVipPackDtoFromJson(Map<String, dynamic> json) =>
    ProductVipPackDto(
      id: json['id'] as String,
      type: json['type'] as String,
      pack: VipPackDto.fromJson(json['vipPack'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductVipPackDtoToJson(ProductVipPackDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'vipPack': instance.pack,
    };
