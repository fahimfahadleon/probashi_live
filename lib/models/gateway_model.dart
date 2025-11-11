import 'package:json_annotation/json_annotation.dart';

part 'gateway_model.g.dart';

@JsonSerializable()
class Gateway {
  final int id;
  final String phone;
  final String provider;

  Gateway({
    required this.id,
    required this.phone,
    required this.provider,
  });

  factory Gateway.fromJson(Map<String, dynamic> json) =>
      _$GatewayFromJson(json);

  Map<String, dynamic> toJson() => _$GatewayToJson(this);
}