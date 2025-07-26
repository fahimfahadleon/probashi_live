import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/participant_video_widget.dart';

import '../models/user_profile.dart';
import '../services/generic_system_service.dart';
import '../utils/api_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';

import '../models/live_comment.dart'; // your model imports
import '../models/live_user.dart';
import 'mini_user_profile_dialog.dart';
import 'one_to_one_chat.dart';

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
  bool showCommentList = true;
  late LiveSession session;
  late String liveName = "default name";

  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  final List<LiveUser> participants = [];
  int viewerCount = 0;
  late String profilePicture = "https://api.dicebear.com/7.x/identicon/png?seed=default";


  @override
  void initState() {
    super.initState();

    // Typed model callbacks
    SocketService.instance.onNewComment((comment) {
      setState(() {
        Utils.printGreenComment(comment.message);
        comments.add(comment);
      });
    });
    SocketService.instance.onParticipantJoined((participant) {
      setState(() => participants.add(participant));
    });
    SocketService.instance.onParticipantLeft((participant) {
      setState(
            () =>
            participants.removeWhere((p) => p.user.id == participant.user.id),
      );
    });

    SocketService.instance.onAudienceJoined((audienceUser) {
      setState(() {
        viewerCount++;
        // Optionally store them somewhere or show UI
      });
    });
    SocketService.instance.onAudienceLeft((callback) {
      setState(() {
        viewerCount--;
        // Optionally store them somewhere or show UI
      });
    });

    SocketService.instance.onSessionUpdated((updatedSession) {
      final updated = updatedSession.participants;

      // Check if participant list actually changed
      final isSameLength = participants.length == updated.length;
      final isSameContent =
          isSameLength &&
              participants.every((p) =>
                  updated.any((u) => u.user.id == p.user.id));

      if (!isSameLength || !isSameContent) {
        setState(() {
          participants
            ..clear()
            ..addAll(updated);
        });
      }

      session = updatedSession;
    });

    SocketService.instance.onLiveEnded((sessionData) {
      if (mounted) {
        GenericStreamService.stopStream();
      }
    });

    SocketService.instance.onLiveStarted((sessionData) {
      setState(() {
        session = sessionData;
        liveName = sessionData.hosts.first.user.name;
        profilePicture = sessionData.hosts.first.user.profilePic;
      });
    });
  }

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
      builder: (context) =>
          AlertDialog(
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
      GenericStreamService.startStream(rtmpUrl);
      SocketService.instance.goLive();
      setState(() => isStreaming = true);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _confirmEndStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: const Text("End Live Stream"),
            content: const Text(
                "Are you sure you want to end the live stream?"),
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
    return confirm ?? false;
  }

  Future<void> _onClosePressed() async {
    if (await _confirmEndStream()) {
      _endStream();
    }
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

  void _toggleMic() async {
    isMicOn = !isMicOn;
    isMicOn
        ? await GenericStreamService.unmute()
        : await GenericStreamService.mute();
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

  void _kickUser(String userId) {
    SocketService.instance.kickParticipant(userId);
  }

  void _muteUser(String userId) {
    SocketService.instance.muteParticipant(userId);
  }

  void _toggleControlsPanel() {
    setState(() => showControlsPanel = !showControlsPanel);
  }

  void _inviteParticipant() {
    // TODO: Implement invite logic
  }

  Widget _buildStreamGrid() {
    if (participants.isEmpty) {
      return const AndroidView(
        viewType: 'generic_stream_view',
        layoutDirection: TextDirection.ltr,
        creationParams: {},
        creationParamsCodec: StandardMessageCodec(),
      );
    }

    final List<Widget> videoSlots = [
      const AndroidView(
        viewType: 'generic_stream_view',
        layoutDirection: TextDirection.ltr,
        creationParams: {},
        creationParamsCodec: StandardMessageCodec(),
      ),
    ];

    videoSlots.addAll(
      participants.map((p) {
        final userId = p.user.id;
        return Stack(
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: ParticipantVideoWidget(
                streamUrl: "${Variables.RTMP_URL}/$userId",
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_off, color: Colors.white),
                    onPressed: () => _muteUser(userId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _kickUser(userId),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );

    return GridView.count(
      crossAxisCount: videoSlots.length <= 2 ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: videoSlots,
    );
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

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery
        .of(context)
        .viewInsets
        .bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(child: _buildStreamGrid()),

          if (isStreaming) ...[
            Positioned(
              top: 40,
              left: 16,
              right: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final tappedUserId = session.hosts.first.userId;

                      // Prevent showing own profile
                      if (tappedUserId == SocketService.instance.userId) return;

                      try {
                        // Load stats and profile
                        UserStats stats = await ApiService.getApiClient().getUserStats(tappedUserId);
                        UserProfile profile = await ApiService.getApiClient().getUserProfile(tappedUserId);
                        profile.stats = stats;

                        _showMiniProfileDialog(profile);
                      } catch (e) {
                        print("Error loading profile: $e");
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(profilePicture),
                      backgroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          liveName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text(
                              "$viewerCount viewers",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _onClosePressed,
                  ),
                ],
              ),
            ),
            if (showCommentList)
              Positioned(
                left: 0,
                bottom: keyboardHeight + 60,
                height: MediaQuery
                    .of(context)
                    .size
                    .height * 0.4,
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                child: ListView.builder(
                  reverse: true,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[comments.length - 1 - index];
                    final userName = c.liveUser.user.name;
                    final message = c.message;
                    final userId = c.liveUser.id;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5), // customize later
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Align top of texts with avatar
                        children: [
                          GestureDetector(
                            onTap: () async {

                              if (c.liveUser.user.id == SocketService.instance.userId) return;

                              UserStats state = await ApiService.getApiClient().getUserStats(c.liveUser.user.id);
                              c.liveUser.user.stats = state;

                              UserProfile profile = await ApiService.getApiClient().getUserProfile(c.liveUser.user.id);
                              UserStats states = await ApiService.getApiClient().getUserStats(c.liveUser.user.id);
                              profile.stats = states;

                              _showMiniProfileDialog(profile);
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage: CachedNetworkImageProvider(
                                c.liveUser.user.profilePic,
                              ),
                              backgroundColor: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow
                                      .ellipsis, // Truncate if too long
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.volume_off,
                                  color: Colors.white,
                                ),
                                onPressed: () => _muteUser(userId),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _kickUser(userId),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            if (showControlsPanel)
              Positioned(
                bottom: keyboardHeight + 60,
                right: 0,
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.2,
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
                        onPressed: _switchCamera,
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleCamera,
                        icon: Icon(
                          isCameraOn ? Icons.videocam : Icons.videocam_off,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleMic,
                        icon: Icon(
                          isMicOn ? Icons.mic : Icons.mic_off,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: participants.length < 5
                            ? _inviteParticipant
                            : null,
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
                      onPressed: () {
                        setState(() => showCommentList = !showCommentList);
                      },
                      icon: Icon(
                        showCommentList
                            ? Icons.chat
                            : Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
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
            ),
          ],
        ],
      ),
    );
  }

  void _showMiniProfileDialog(UserProfile userProfile) {
    showDialog(
      context: context,
      builder: (context) =>
          MiniUserProfileDialog(
            userProfile: userProfile,
            onRelationToggle: () async {
              try {
                final newRelation = await Utils.toggleFollowStatus(
                    userProfile);
               return newRelation;
              } catch (e) {
                print(e);
                return UserRelation(isFollowing: false, isFriend: false);
              }
            },
            onMessage: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    currentUserId: SocketService.instance.userId,
                    otherUserId: userProfile.id,
                  ),
                ),
              );

            },
          ),
    );
  }
}
