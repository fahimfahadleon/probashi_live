import 'package:json_annotation/json_annotation.dart';
import 'package:probashi_live/models/vip_diamond_pack.dart';

import 'package:probashi_live/models/offer.dart';

part 'create_payment_dto.g.dart';

@JsonSerializable()
class CreatePaymentDto {
  final String transactionId;
  final String method;
  final String productId; // changed from itemId to productId
  final String? description;

  CreatePaymentDto({
    required this.transactionId,
    required this.method,
    required this.productId,
    this.description,
  });

  factory CreatePaymentDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentDtoToJson(this);
}


@JsonSerializable()
class PaymentDto {
  final String id;
  final String transactionId;
  final String method;
  final String status;
  final String userId;
  final String productId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  final VipPackDto? vipPack;
  final OfferDto? offer;

  PaymentDto({
    required this.id,
    required this.transactionId,
    required this.method,
    required this.status,
    required this.userId,
    required this.productId,
    this.description,
    this.vipPack,
    this.offer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);
}

@JsonSerializable()
class PaymentHistoryDto {
  final String id;
  final String paymentId;
  final String userId;
  final int? diamonds;
  final double price;
  final String eventType;
  final String? description;
  final DateTime createdAt;

  PaymentHistoryDto({
    required this.id,
    required this.paymentId,
    required this.userId,
    this.diamonds,
    required this.price,
    required this.eventType,
    this.description,
    required this.createdAt,
  });

  factory PaymentHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$PaymentHistoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentHistoryDtoToJson(this);
}