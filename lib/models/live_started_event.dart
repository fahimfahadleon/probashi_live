import 'package:json_annotation/json_annotation.dart';
import 'live_session.dart';
import 'webrtc_response.dart';

part 'live_started_event.g.dart';

@JsonSerializable(explicitToJson: true)
class LiveStartedEvent {
  @JsonKey(name: 'fullSession')
  final LiveSession fullSession;

  @JsonKey(name: 'webrtc')
  final WebRTCResponse webrtc;

  LiveStartedEvent({
    required this.fullSession,
    required this.webrtc,
  });

  factory LiveStartedEvent.fromJson(Map<String, dynamic> json) =>
      _$LiveStartedEventFromJson(json);

  Map<String, dynamic> toJson() => _$LiveStartedEventToJson(this);
}