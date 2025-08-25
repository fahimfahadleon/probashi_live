import 'package:flutter/services.dart';

class GenericStreamService {
  static const MethodChannel _channel = MethodChannel('rtmp_channel');

  /// Start the RTMP stream with a provided [url]
  static Future<bool> startStream(String url) async {
    try {
      final result = await _channel.invokeMethod<String>('startStream', {'url': url});
      return result == 'started';
    } on PlatformException catch (e) {
      print('Error starting stream: ${e.message}');
      return false;
    }
  }

  /// Stop the current RTMP stream
  static Future<bool> stopStream() async {
    try {
      final result = await _channel.invokeMethod<String>('stopStream');
      return result == 'stopped';
    } on PlatformException catch (e) {
      print('Error stopping stream: ${e.message}');
      return false;
    }
  }
  /// Stop the current RTMP stream
  static Future<bool> initialize() async {
    try {
      final result = await _channel.invokeMethod<String>('initialize');
      return result == 'stopped';
    } on PlatformException catch (e) {
      print('Error stopping stream: ${e.message}');
      return false;
    }
  }
  /// Stop the current RTMP stream
  static Future<bool> startPreview() async {
    try {
      final result = await _channel.invokeMethod<String>('startPreview');
      return result == 'stopped';
    } on PlatformException catch (e) {
      print('Error stopping stream: ${e.message}');
      return false;
    }
  }
  /// Stop the current RTMP stream
  static Future<bool> stopPreview() async {
    try {
      final result = await _channel.invokeMethod<String>('stopPreview');
      return result == 'stopped';
    } on PlatformException catch (e) {
      print('Error stopping stream: ${e.message}');
      return false;
    }
  }

  /// Switch between front and back cameras
  static Future<void> switchCamera() async {
    try {
      await _channel.invokeMethod('switchCamera');
    } catch (e) {
      print('Error switching camera: $e');
    }
  }

  /// Mute the stream audio
  static Future<void> mute() async {
    try {
      await _channel.invokeMethod('mute');
    } catch (e) {
      print('Error muting audio: $e');
    }
  }

  /// Unmute the stream audio
  static Future<void> unmute() async {
    try {
      await _channel.invokeMethod('unmute');
    } catch (e) {
      print('Error unmuting audio: $e');
    }
  }
}
