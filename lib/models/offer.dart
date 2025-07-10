import 'package:json_annotation/json_annotation.dart';

part 'offer.g.dart';

@JsonSerializable()
class Offer {
  final String id;
  final String title;
  final String content;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;

  Offer({
    required this.id,
    required this.title,
    required this.content,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Offer.fromJson(Map<String, dynamic> json) => _$OfferFromJson(json);
  Map<String, dynamic> toJson() => _$OfferToJson(this);
}