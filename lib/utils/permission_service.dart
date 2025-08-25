import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestPermission(
      BuildContext context, {
        required VoidCallback onGranted,
        required VoidCallback onDenied,
      }) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (statuses[Permission.camera]!.isGranted &&
        statuses[Permission.microphone]!.isGranted) {
      onGranted();
    } else {
      onDenied();
    }
  }
}