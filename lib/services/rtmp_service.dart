import 'package:flutter/services.dart';

class RtmpService {
  static const MethodChannel _channel = MethodChannel('rtmp_channel');

  static Future<void> startStream(String url) async {
    await _channel.invokeMethod('startStream', {'url': url});
  }

  static Future<void> stopStream() async {
    await _channel.invokeMethod('stopStream');
  }
  static Future<void> toggleCamera() async {
    await _channel.invokeMethod('toggleCamera');
  }

  static Future<void> toggleVideo() async {
    await _channel.invokeMethod('toggleVideo');
  }

  static Future<void> toggleAudio() async {
    await _channel.invokeMethod('toggleAudio');
  }
}
