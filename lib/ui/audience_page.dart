import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

// class AudiencePage extends StatefulWidget {
//   final String streamUrl;
//
//   const AudiencePage({Key? key, required this.streamUrl}) : super(key: key);
//
//   @override
//   State<AudiencePage> createState() => _AudiencePageState();
// }
//
// class _AudiencePageState extends State<AudiencePage> {
//   late VlcPlayerController _controller;
//
//   @override
//   void initState() {
//     super.initState();
//     print(widget.streamUrl);
//
//     // Lock orientation to portrait up only
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//
//     _controller = VlcPlayerController.network(widget.streamUrl, autoPlay: true);
//
//     _controller.addOnInitListener(() async {
//       _controller.setVideoAspectRatio("16/9");
//
//       var videoAspectRatio = await _controller.getVideoAspectRatio();
//       print("aspect ratio: " + videoAspectRatio!);
//     });
//   }
//
//   @override
//   void dispose() {
//     // Unlock orientation on dispose
//     SystemChrome.setPreferredOrientations(DeviceOrientation.values);
//
//     _controller.stop();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // final screenSize = MediaQuery.of(context).size;
//     // final screenAspectRatio = screenSize.width / screenSize.height;
//
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Make VLC player fill entire screen with correct aspect ratio
//           Positioned.fill(
//             child: VlcPlayer(
//               controller: _controller,
//               aspectRatio: 9/16,
//               placeholder: const Center(child: CircularProgressIndicator()),
//             ),
//           ),
//
//           // Close button on top right
//           Positioned(
//             top: 40,
//             right: 16,
//             child: IconButton(
//               icon: const Icon(Icons.close, color: Colors.white),
//               onPressed: () => Navigator.pop(context),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:probashi_live/models/live_session.dart';

import '../models/live_comment.dart';
import '../models/live_user.dart';
import '../utils/socket_service.dart';
import '../utils/variables.dart';

class AudiencePage extends StatefulWidget {
  final LiveSession liveSession;
  final String sessionId;
  final String hostUserId;
  final String streamerName;

  AudiencePage({required this.liveSession, super.key})
      : sessionId = liveSession.id,
        hostUserId = liveSession.hosts.first.user.id,
        streamerName = liveSession.hosts.first.user.name;

  @override
  State<AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  final List<LiveUser> participants = [];
  bool showCommentList = true;
  bool showControlsPanel = false;

  @override
  void initState() {
    super.initState();

    SocketService.instance.joinAudience(widget.sessionId);

    SocketService.instance.onNewComment((comment) {
      setState(() => comments.add(comment));
    });

    SocketService.instance.onParticipantJoined((participant) {
      setState(() => participants.add(participant));
    });

    SocketService.instance.onParticipantLeft((participant) {
      final leftUser = participant;
      setState(() {
        participants.removeWhere((p) => p.user.id == leftUser.user.id);
      });
    });
  }

  void _sendComment() {
    final msg = _chatController.text.trim();
    if (msg.isNotEmpty) {
      SocketService.instance.sendComment(msg);
      _chatController.clear();
    }
  }

  Widget _buildStreamGrid() {
    String streamUrl = "${Variables.RTMP_URL}/${widget.hostUserId}";

    if (participants.isEmpty) {
      return SizedBox.expand(
        child: VlcPlayer(
          controller: VlcPlayerController.network(
            streamUrl,
            hwAcc: HwAcc.full,
            autoPlay: true,
            options: VlcPlayerOptions(),
          ),
          aspectRatio: 16 / 9, // required but overridden by SizedBox.expand
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final List<Widget> videoWidgets = [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: ParticipantVideoWidget(streamUrl: streamUrl),
      ),
    ];

    videoWidgets.addAll(
      participants.map((p) {
        final userId = p.user.id;
        String streamUrl = "${Variables.RTMP_URL}/$userId";
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: ParticipantVideoWidget(streamUrl: streamUrl),
        );
      }),
    );

    return GridView.count(
      crossAxisCount: videoWidgets.length <= 2 ? 2 : 3,
      children: videoWidgets,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
  @override
  void dispose() {
    SocketService.instance.leaveLive();
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          participants.isEmpty
              ? _buildStreamGrid()
              : Positioned.fill(child: _buildStreamGrid()),

          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.streamerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          if (showCommentList)
            Positioned(
              left: 0,
              bottom: keyboardHeight + 60,
              height: MediaQuery.of(context).size.height * 0.4,
              width: MediaQuery.of(context).size.width * 0.8,
              child: ListView.builder(
                reverse: true,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[comments.length - 1 - index];
                  final userName = c.liveUser.user.name;
                  final message = c.message;
                  return ListTile(
                    title: Text(
                      "$userName: $message",
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),

          if (showControlsPanel)
            Positioned(
              bottom: keyboardHeight + 60,
              right: 0,
              width: MediaQuery.of(context).size.width * 0.2,
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  border: Border.all(color: Colors.white70, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                      ),
                      tooltip: "Send Gift",
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: keyboardHeight,
            child: Container(
              color: Colors.black45,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: "Type a comment...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendComment,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => showCommentList = !showCommentList),
                    icon: Icon(
                      showCommentList ? Icons.chat : Icons.chat_bubble_outline,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: () =>
                        setState(() => showControlsPanel = !showControlsPanel),
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
          ),
        ],
      ),
    );
  }
}

class ParticipantVideoWidget extends StatefulWidget {
  final String streamUrl;

  const ParticipantVideoWidget({super.key, required this.streamUrl});

  @override
  State<ParticipantVideoWidget> createState() => _ParticipantVideoWidgetState();
}

class _ParticipantVideoWidgetState extends State<ParticipantVideoWidget> {
  late VlcPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: _controller,
      aspectRatio: 9 / 16,
      placeholder: const Center(child: CircularProgressIndicator()),
    );
  }
}
