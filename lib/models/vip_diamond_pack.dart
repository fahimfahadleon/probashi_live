import 'package:json_annotation/json_annotation.dart';

part 'vip_diamond_pack.g.dart';

@JsonSerializable()
class VIPDiamondPack {
  final String id;
  final double price;
  final int diamonds;
  final DateTime createdAt;
  final DateTime updatedAt;

  VIPDiamondPack({
    required this.id,
    required this.price,
    required this.diamonds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VIPDiamondPack.fromJson(Map<String, dynamic> json) =>
      _$VIPDiamondPackFromJson(json);

  Map<String, dynamic> toJson() => _$VIPDiamondPackToJson(this);
}