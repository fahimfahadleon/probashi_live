import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@JsonSerializable()
class OfferDto {
  final String id;
  final String title;
  final String content;
  final int diamonds;
  final double price;
  final DateTime createdAt;

  OfferDto({
    required this.id,
    required this.title,
    required this.content,
    required this.diamonds,
    required this.price,
    required this.createdAt,
  });

  factory OfferDto.fromJson(Map<String, dynamic> json) => _$OfferDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OfferDtoToJson(this);
}

@JsonSerializable()
class ProductOfferDto {
  final String id;
  final String type;
  final OfferDto offer;

  ProductOfferDto({
    required this.id,
    required this.type,
    required this.offer,
  });

  factory ProductOfferDto.fromJson(Map<String, dynamic> json) =>
      _$ProductOfferDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOfferDtoToJson(this);
}