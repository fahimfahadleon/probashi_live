// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferDto _$OfferDtoFromJson(Map<String, dynamic> json) => OfferDto(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      diamonds: (json['diamonds'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$OfferDtoToJson(OfferDto instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'diamonds': instance.diamonds,
      'price': instance.price,
      'createdAt': instance.createdAt.toIso8601String(),
    };

ProductOfferDto _$ProductOfferDtoFromJson(Map<String, dynamic> json) =>
    ProductOfferDto(
      id: json['id'] as String,
      type: json['type'] as String,
      offer: OfferDto.fromJson(json['offer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ProductOfferDtoToJson(ProductOfferDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'offer': instance.offer,
    };
