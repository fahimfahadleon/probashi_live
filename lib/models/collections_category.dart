import 'package:json_annotation/json_annotation.dart';
import 'gift.dart';

part 'collections_category.g.dart';

@JsonSerializable()
class CollectionsCategory {
  final String id;
  final String name;

  @JsonKey(name: 'collections') // Match backend key
  final List<Gift> gifts;

  CollectionsCategory({
    required this.id,
    required this.name,
    required this.gifts,
  });

  factory CollectionsCategory.fromJson(Map<String, dynamic> json) =>
      _$CollectionsCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$CollectionsCategoryToJson(this);
}