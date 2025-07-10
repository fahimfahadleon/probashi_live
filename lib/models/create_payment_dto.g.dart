// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaymentDto _$CreatePaymentDtoFromJson(Map<String, dynamic> json) =>
    CreatePaymentDto(
      transactionId: json['transactionId'] as String,
      method: json['method'] as String,
      itemId: json['itemId'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreatePaymentDtoToJson(CreatePaymentDto instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'method': instance.method,
      'itemId': instance.itemId,
      'description': instance.description,
    };
