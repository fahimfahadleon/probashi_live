// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gateway_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gateway _$GatewayFromJson(Map<String, dynamic> json) => Gateway(
      id: (json['id'] as num).toInt(),
      phone: json['phone'] as String,
      provider: json['provider'] as String,
    );

Map<String, dynamic> _$GatewayToJson(Gateway instance) => <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'provider': instance.provider,
    };
