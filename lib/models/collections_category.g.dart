// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collections_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CollectionsCategory _$CollectionsCategoryFromJson(Map<String, dynamic> json) =>
    CollectionsCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      gifts: (json['collections'] as List<dynamic>)
          .map((e) => Gift.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CollectionsCategoryToJson(
        CollectionsCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'collections': instance.gifts,
    };
