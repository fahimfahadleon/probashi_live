import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/comment_list.dart';
import 'package:svgaplayer_flutter/player.dart';

import '../models/gift.dart';
import '../models/user_profile.dart';
import '../services/generic_system_service.dart';
import '../utils/api_service.dart';
import '../utils/permission_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';

import '../models/live_comment.dart'; // your model imports
import '../models/live_user.dart';
import 'cached_circle_avatar.dart';

class ParticipantPage extends StatefulWidget {
  final String sessionId;
  final String from;
  final String to;

  const ParticipantPage({
    super.key,
    required this.sessionId,
    required this.from,
    required this.to,
  });

  @override
  State<ParticipantPage> createState() => _ParticipantPageState();
}

class _ParticipantPageState extends State<ParticipantPage>
    with TickerProviderStateMixin {
  bool isStreaming = false;
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isFrontCamera = true;
  bool isSessionLoaded = false;
  bool showControlsPanel = false;
  bool showCommentList = true;
  late LiveSession session;
  late String liveName = "default name";

  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  late List<LiveUser> participants = [];
  int viewerCount = 0;
  List<LiveUser>list = [];
  late String profilePicture =
      "https://api.dicebear.com/7.x/identicon/png?seed=default";

  SVGAAnimationController? _svgaController;
  bool _showGiftAnimation = false;
  String _giftSenderName = '';
  String _giftReceiverName = '';
bool isParticipantAvail = false;
  @override
  void initState() {
    super.initState();


    PermissionService.requestPermission(
      context,
      onGranted: () {
        GenericStreamService.initialize();
        SocketService.instance.acceptInvite(fromUserId: widget.from, userId: widget.to, sessionId: widget.sessionId);
        _svgaController = SVGAAnimationController(vsync: this);

        SocketService.instance.requestLiveSessionDetails(widget.sessionId);

        SocketService.instance.onGiftReceived((gift1) async {
          final gift = Gift.fromJson(gift1['gift']);
          final fromUser = UserProfile.fromJson(gift1['fromUser']);
          final toUser = UserProfile.fromJson(gift1['toUser']);

          final url = Variables.BASE_URL + gift.imageUrl;
          final videoItem = await Utils.getCachedSvga(url);
          if (!mounted || videoItem == null) return;


          setState(() {
            _svgaController!.videoItem = videoItem;
            _showGiftAnimation = true;
            _giftSenderName = fromUser.name;
            _giftReceiverName = toUser.name;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _svgaController!.reset();
            _svgaController!.repeat(count: 1).whenComplete(() {
              if (!mounted) return;
              setState(() => _showGiftAnimation = false);
            });
          });
        });

        SocketService.instance.onLiveDetailData((data) {
          setState(() {
            session = data;

            print("session: ${session.toJson()}");

            liveName = session.hosts.first.user.name;
            profilePicture = session.hosts.first.user.profilePic;
            isSessionLoaded = true; // mark as ready
          });
        });
        // Typed model callbacks
        SocketService.instance.onNewComment((comment) {
          const joinSuffix = "has joined the Live.!@";

          if (comment.message.contains(joinSuffix)) {
            Utils.handleUserJoined(context, comment.liveUser.user);

            final cleanedMessage = comment.message.replaceAll("!@", "");
            final modifiedComment = LiveComment(
              id: comment.id,
              liveUser: comment.liveUser,
              message: cleanedMessage,
              createdAt: comment.createdAt,
            );

            setState(() {
              comments.add(modifiedComment);
            });
          } else {
            setState(() {
              comments.add(comment);
            });
          }
        });
        SocketService.instance.onParticipantJoined((participant) {});
        SocketService.instance.onParticipantLeft((participant) {
          setState(
                () => participants.removeWhere((p) => p.user.id == participant.user.id),
          );
        });

        SocketService.instance.onAudienceJoined((audienceUser) {

        });
        SocketService.instance.onAudienceLeft((callback) {

        });

        SocketService.instance.onSessionUpdated((updatedSession) {
          setState(() {
            session = updatedSession;
            viewerCount = updatedSession.audience.length;
            list = [
              ...updatedSession.audience.where((u) => u.user.vipStatus),
              ...updatedSession.audience.where((u) => !u.user.vipStatus),
            ];
            participants = Utils.addLiveUsersWithoutDuplicates(
              participants,
              session.participants,
            );
          });
        });

        SocketService.instance.onLiveEnded((sessionData) {
          if (mounted) {
            GenericStreamService.stopStream();
            Utils.showSnackbar(context, "Live ended");
            Navigator.pop(context);
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startStreamAutomatically();
        });

        SocketService.instance.onParticipantLiveStarted((data) {
          setState(() {
            session = data;
            liveName = session.hosts.first.user.name;
            profilePicture = session.hosts.first.user.profilePic;
          });
        });

      },
      onDenied: () {
        SocketService.instance.cancelInvite(fromUserId: widget.from, toUserId:widget.to, sessionId: widget.sessionId);
        Utils.showSnackbar(context, "Permission Denied");
        Navigator.pop(context);
      },
    );


  }

  void _startStreamAutomatically() {
    final rtmpUrl = "${Variables.RTMP_URL}/${SocketService.instance.userId}";
    GenericStreamService.startStream(rtmpUrl);
    print("Streaming At: $rtmpUrl");
    SocketService.instance.participantLive(widget.sessionId);
    setState(() => isStreaming = true);
  }

  void addParticipant() {
    SocketService.instance.participantLive(widget.sessionId);
  }

  Future<bool> _confirmEndStream() async {
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
    return confirm ?? false;
  }

  Future<void> _onClosePressed() async {
    if (await _confirmEndStream()) {
      _endStream();
    }
  }

  void _endStream() {
    GenericStreamService.stopStream();
    SocketService.instance.participantLeft();
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

  void _toggleControlsPanel() {
    setState(() => showControlsPanel = !showControlsPanel);
  }

  Widget _buildStreamGrid() {
    String hostId = session.hosts.first.user.id;
    UserProfile hostUserProfile = session.hosts.first.user;
    final guestParticipants = participants
        .where((user) => user.userId != SocketService.instance.userId)
        .toList(); // Only up to 4 guests

    // --- Top Row: Host + Self (AndroidView) ---
    final topRow = Row(
      children: [
        // Host VLC stream
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Utils.getParticipant(context, hostId, hostUserProfile, widget.sessionId)
            ),
          ),
        ),
        // Self AndroidView
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: const AndroidView(
                viewType: 'generic_stream_view',
                layoutDirection: TextDirection.ltr,
                creationParams: {},
                creationParamsCodec: StandardMessageCodec(),
              ),
            ),
          ),
        ),
      ],
    );

    // --- Bottom Guest Row (up to 4 guests) ---



    if(guestParticipants.isNotEmpty){
      isParticipantAvail = true;
    }else{
      isParticipantAvail = false;
    }

    final guestRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        if (index < guestParticipants.length) {
          final p = guestParticipants[index];
          final userId = p.userId;
          final userProfile = p.user;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Utils.getParticipant(context, userId, userProfile, widget.sessionId)
                ),
              ),
            ),
          );
        } else {
          // Return invisible slot (not a placeholder)
          return const Expanded(child: SizedBox.shrink());
        }
      }),
    );

    // Return full layout
    return Column(
      children: [
        topRow,
        const SizedBox(height: 8),
        guestParticipants.isNotEmpty ? guestRow : const SizedBox.shrink(),
      ],
    );
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    _chatController.dispose();
    participants.clear();
    viewerCount = 0;

    if (isStreaming) {
      GenericStreamService.stopStream();
      // SocketService.instance.leaveLive();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    if (!isSessionLoaded) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, -1),
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: _buildStreamGrid(),
              ),
            ),
          ),

          if (_showGiftAnimation)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // SVGA Animation
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: SVGAImage(_svgaController!),
                      ),

                      // Floating Text at 20% screen height
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.1,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(
                                alpha: (0.6 * 255).toDouble(),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black45,
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: _giftSenderName,
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' sent a gift to ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _giftReceiverName,
                                    style: const TextStyle(
                                      color: Colors.lightBlueAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isStreaming) ...[
            Positioned(
              top: 0,
              left: 4,
              right: 4,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  // Vertically center all
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final tappedUserId = session.hosts.first.userId;
                        if (tappedUserId == SocketService.instance.userId) {
                          return;
                        }
                        try {
                          UserStats stats = await ApiService.getApiClient()
                              .getUserStats(tappedUserId);
                          UserProfile profile = await ApiService.getApiClient()
                              .getUserProfile(tappedUserId);
                          profile.stats = stats;
                          Utils.showMiniProfileDialog(userProfile: profile,context: context);
                        } catch (e) {
                          print("Error loading profile: $e");
                        }
                      },
                      child: CachedCircleAvatar(
                        imageUrl: profilePicture,
                        user: session.hosts.first.user.settings,
                        radius: 20,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Name + viewer count (same row)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  liveName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.remove_red_eye,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "$viewerCount",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          /// Horizontal ListView (below name)
                          SizedBox(
                            height: 28,
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              scrollDirection: Axis.horizontal,
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                              const SizedBox(width: 1),
                              itemBuilder: (context, index) {
                                final user = list[index];
                                return SizedBox(
                                  width: 28, // radius * 2
                                  child: CachedCircleAvatar(
                                    imageUrl: user.user.profilePic,
                                    user: user.user.settings,
                                    radius: 14,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _onClosePressed,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (showCommentList)
              Positioned(
                left: 0,
                bottom: keyboardHeight + 60,
                height: isParticipantAvail?MediaQuery.of(context).size.height * 0.2 : MediaQuery.of(context).size.height * 0.3,
                width: MediaQuery.of(context).size.width * 0.8,
                child: CommentList(comments: comments),
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
                    color: Colors.black.withValues(
                      alpha: (0.6 * 255).toDouble(),
                    ),
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

                    // IconButton(
                    //   onPressed: () {
                    //     setState(() {
                    //       addParticipant();
                    //     });
                    //   },
                    //   icon: Icon(Icons.add, color: Colors.white),
                    // ),

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
}
