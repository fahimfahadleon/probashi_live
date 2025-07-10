// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vip_diamond_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VIPDiamondPack _$VIPDiamondPackFromJson(Map<String, dynamic> json) =>
    VIPDiamondPack(
      id: json['id'] as String,
      price: (json['price'] as num).toDouble(),
      diamonds: (json['diamonds'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$VIPDiamondPackToJson(VIPDiamondPack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'diamonds': instance.diamonds,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
