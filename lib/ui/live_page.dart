import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../services/rtmp_service.dart';

class LivePage extends StatefulWidget {
  final String rtmpUrl;

  const LivePage({super.key, required this.rtmpUrl});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  @override
  void initState() {
    super.initState();
    // Optionally start stream here
    // RtmpService.startStream(widget.rtmpUrl);
  }

  @override
  void dispose() {
    RtmpService.stopStream();
    super.dispose();
  }

  void _cancelStream() {
    RtmpService.stopStream();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AndroidView(
            viewType: 'rtmp_camera_view',
            layoutDirection: TextDirection.ltr,
            creationParams: <String, dynamic>{},
            creationParamsCodec: StandardMessageCodec(),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _cancelStream,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Cancel Stream", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    RtmpService.startStream(widget.rtmpUrl);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text("Start Stream", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
