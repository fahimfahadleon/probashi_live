// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_started_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveStartedEvent _$LiveStartedEventFromJson(Map<String, dynamic> json) =>
    LiveStartedEvent(
      fullSession:
          LiveSession.fromJson(json['fullSession'] as Map<String, dynamic>),
      webrtc: WebRTCResponse.fromJson(json['webrtc'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LiveStartedEventToJson(LiveStartedEvent instance) =>
    <String, dynamic>{
      'fullSession': instance.fullSession.toJson(),
      'webrtc': instance.webrtc.toJson(),
    };
