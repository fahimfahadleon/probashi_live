import 'package:json_annotation/json_annotation.dart';

import 'gateway_model.dart';
part 'settings_model.g.dart';

@JsonSerializable()
class Settings {
  final int id;
  final double profitMargin;
  final List<Gateway>? gateways;
  final Map<String, dynamic>? appSettings;

  Settings({
    required this.id,
    required this.profitMargin,
    this.gateways,
    this.appSettings,
  });

  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}