// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Settings _$SettingsFromJson(Map<String, dynamic> json) => Settings(
      id: (json['id'] as num).toInt(),
      profitMargin: (json['profitMargin'] as num).toDouble(),
      gateways: (json['gateways'] as List<dynamic>?)
          ?.map((e) => Gateway.fromJson(e as Map<String, dynamic>))
          .toList(),
      appSettings: json['appSettings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SettingsToJson(Settings instance) => <String, dynamic>{
      'id': instance.id,
      'profitMargin': instance.profitMargin,
      'gateways': instance.gateways,
      'appSettings': instance.appSettings,
    };
