import 'package:json_annotation/json_annotation.dart';

part 'gift.g.dart';

@JsonSerializable()
class Gift {
  final String id;
  final String name;
  final String imageUrl;
  final String thumbnailUrl; // 👈 new
  final int price;

  Gift({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.thumbnailUrl, // 👈 new
    required this.price,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => _$GiftFromJson(json);
  Map<String, dynamic> toJson() => _$GiftToJson(this);
}
