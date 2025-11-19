import 'package:json_annotation/json_annotation.dart';

part 'vip_diamond_pack.g.dart';

@JsonSerializable()
class VipPackDto {
  final String id;
  final int diamonds;
  final double price;
  final DateTime createdAt;

  VipPackDto({
    required this.id,
    required this.diamonds,
    required this.price,
    required this.createdAt,
  });

  factory VipPackDto.fromJson(Map<String, dynamic> json) => _$VipPackDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VipPackDtoToJson(this);
}

@JsonSerializable()
class ProductVipPackDto {
  final String id;
  final String type;
  @JsonKey(name: 'vipPack')
  final VipPackDto pack;

  ProductVipPackDto({
    required this.id,
    required this.type,
    required this.pack,
  });

  factory ProductVipPackDto.fromJson(Map<String, dynamic> json) =>
      _$ProductVipPackDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductVipPackDtoToJson(this);
}