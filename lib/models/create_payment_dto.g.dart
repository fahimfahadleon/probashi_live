// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_payment_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePaymentDto _$CreatePaymentDtoFromJson(Map<String, dynamic> json) =>
    CreatePaymentDto(
      transactionId: json['transactionId'] as String,
      method: json['method'] as String,
      productId: json['productId'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$CreatePaymentDtoToJson(CreatePaymentDto instance) =>
    <String, dynamic>{
      'transactionId': instance.transactionId,
      'method': instance.method,
      'productId': instance.productId,
      'description': instance.description,
    };

PaymentDto _$PaymentDtoFromJson(Map<String, dynamic> json) => PaymentDto(
      id: json['id'] as String,
      transactionId: json['transactionId'] as String,
      method: json['method'] as String,
      status: json['status'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      description: json['description'] as String?,
      vipPack: json['vipPack'] == null
          ? null
          : VipPackDto.fromJson(json['vipPack'] as Map<String, dynamic>),
      offer: json['offer'] == null
          ? null
          : OfferDto.fromJson(json['offer'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PaymentDtoToJson(PaymentDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'transactionId': instance.transactionId,
      'method': instance.method,
      'status': instance.status,
      'userId': instance.userId,
      'productId': instance.productId,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'vipPack': instance.vipPack,
      'offer': instance.offer,
    };

PaymentHistoryDto _$PaymentHistoryDtoFromJson(Map<String, dynamic> json) =>
    PaymentHistoryDto(
      id: json['id'] as String,
      paymentId: json['paymentId'] as String,
      userId: json['userId'] as String,
      diamonds: (json['diamonds'] as num?)?.toInt(),
      price: (json['price'] as num).toDouble(),
      eventType: json['eventType'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$PaymentHistoryDtoToJson(PaymentHistoryDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'paymentId': instance.paymentId,
      'userId': instance.userId,
      'diamonds': instance.diamonds,
      'price': instance.price,
      'eventType': instance.eventType,
      'description': instance.description,
      'createdAt': instance.createdAt.toIso8601String(),
    };
