import 'package:json_annotation/json_annotation.dart';
import 'gift.dart';

part 'gift_category.g.dart';

@JsonSerializable()
class Category {
  final String id;
  final String name;
  final List<Gift> gifts;

  Category({
    required this.id,
    required this.name,
    required this.gifts,
  });

  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}