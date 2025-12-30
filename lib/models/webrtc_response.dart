import 'package:json_annotation/json_annotation.dart';

part 'webrtc_response.g.dart';

@JsonSerializable(explicitToJson: true)
class WebRTCResponse {
  final String token;
  final String url;

  WebRTCResponse({
    required this.token,
    required this.url,
  });

  factory WebRTCResponse.fromJson(Map<String, dynamic> json) =>
      _$WebRTCResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WebRTCResponseToJson(this);
}