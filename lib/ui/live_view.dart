import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/generic_system_service.dart';
import '../utils/socket_service.dart';
import '../utils/variables.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  bool isStreaming = false;
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isFrontCamera = true;
  bool _dialogShown = false;
  bool showControlsPanel = false;

  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> comments = [];

  int viewerCount = 0; // Update dynamically as needed
  String streamerName = "Streamer"; // Update dynamically as needed

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.delayed(Duration.zero, () => _showConfirmationDialog());
    }
  }

  Future<void> _showConfirmationDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Start Live Stream?"),
        content: const Text("Do you want to go live now?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final rtmpUrl = "${Variables.RTMP_URL}/${SocketService.instance.userId}";
      print("RTMP URL: $rtmpUrl");

      GenericStreamService.startStream(rtmpUrl);
      SocketService.instance.goLive();
      setState(() {
        isStreaming = true;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _confirmEndStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("End Live Stream"),
        content: const Text("Are you sure you want to end the live stream?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("End"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _endStream();
    }
  }

  @override
  void dispose() {
    if (isStreaming) {
      GenericStreamService.stopStream();
      SocketService.instance.leaveLive();
    }
    _chatController.dispose();
    super.dispose();
  }

  void _toggleMic() async {
    isMicOn = !isMicOn;
    isMicOn ? await GenericStreamService.unmute() : await GenericStreamService.mute();
    setState(() {});
  }

  void _toggleCamera() {
    isCameraOn = !isCameraOn;
    setState(() {});
  }

  void _switchCamera() async {
    isFrontCamera = !isFrontCamera;
    await GenericStreamService.switchCamera();
    setState(() {});
  }

  void _endStream() {
    GenericStreamService.stopStream();
    SocketService.instance.leaveLive();
    Navigator.pop(context);
  }

  void _sendComment() {
    final msg = _chatController.text.trim();
    if (msg.isNotEmpty) {
      SocketService.instance.sendComment(msg);
      _chatController.clear();
    }
  }

  void _toggleControlsPanel() {
    setState(() {
      showControlsPanel = !showControlsPanel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Prevent whole scaffold from resizing
      body: Stack(
        children: [
          SizedBox.expand(
            child: const AndroidView(
              viewType: 'generic_stream_view',
              layoutDirection: TextDirection.ltr,
              creationParams: {},
              creationParamsCodec: StandardMessageCodec(),
            ),
          ),
          if (isStreaming) ...[
            Positioned(
              top: 40,
              right: 16,
              left: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          streamerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.remove_red_eye,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          viewerCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: _confirmEndStream,
                  ),
                ],
              ),
            ),
            if (showControlsPanel)
              Positioned(
                bottom: 120,
                left: 8,
                right: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white38),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _switchCamera,
                        icon:
                        const Icon(Icons.cameraswitch, color: Colors.white),
                        tooltip: "Switch Camera",
                      ),
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: Icon(
                            isCameraOn ? Icons.videocam : Icons.videocam_off,
                            color: Colors.white),
                        tooltip: "Toggle Camera",
                      ),
                      IconButton(
                        onPressed: _toggleMic,
                        icon:
                        Icon(isMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
                        tooltip: "Toggle Mic",
                      ),
                      IconButton(
                        onPressed: () {
                          // Invite users functionality here
                        },
                        icon: const Icon(Icons.group_add, color: Colors.white),
                        tooltip: "Add People",
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: keyboardHeight, // Move up by keyboard height only
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: mediaQuery.size.height * 0.5 - 60,
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.topLeft,
                    color: Colors.transparent, // fully transparent
                    child: ListView.builder(
                      reverse: true,
                      shrinkWrap: true,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[comments.length - 1 - index];
                        final userName = comment['user']?['name'] ?? "User";
                        final message = comment['message'] ?? "";
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "$userName: ",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                TextSpan(
                                  text: message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    color: Colors.black54,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Type a comment...",
                              hintStyle:
                              const TextStyle(color: Colors.grey),
                              filled: true,
                              fillColor: Colors.black38,
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Colors.white30),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.all(Radius.circular(12)),
                                borderSide: BorderSide(color: Colors.white),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            onSubmitted: (_) => _sendComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _sendComment,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: _toggleControlsPanel,
                          icon: Icon(
                            showControlsPanel
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
