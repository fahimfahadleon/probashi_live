import 'package:json_annotation/json_annotation.dart';

part 'create_payment_dto.g.dart';

@JsonSerializable()
class CreatePaymentDto {
  final String transactionId;
  final String method;
  final String itemId;
  final String? description;

  CreatePaymentDto({
    required this.transactionId,
    required this.method,
    required this.itemId,
    this.description,
  });

  factory CreatePaymentDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentDtoToJson(this);
}