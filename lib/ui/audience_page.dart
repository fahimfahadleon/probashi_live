import 'package:flutter/material.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/comment_list.dart';
import 'package:probashi_live/ui/participant_video_widget.dart';
import 'package:svgaplayer_flutter/player.dart';

import '../models/gift.dart';
import '../models/live_comment.dart';
import '../models/live_user.dart';
import '../models/user_profile.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';
import 'cached_circle_avatar.dart';

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

class _AudiencePageState extends State<AudiencePage>
    with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  final List<LiveUser> participants = [];
  bool isParticipantAvail = false;
  SVGAAnimationController? _svgaController;
  bool _showGiftAnimation = false;

  String _giftSenderName = ""; // store sender username
  String _giftReceiverName = "";
  int _giftAmount = 0;
  List<LiveUser> list = [];
  bool isMuted = false;
  bool showCommentList = true;
  bool showControlsPanel = false;

  int viewerCount = 0;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);
    SocketService.instance.joinAudience(widget.sessionId);
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
    SocketService.instance.onParticipantJoined((participant) {
      // setState(() => participants.add(participant));
    });
    SocketService.instance.onAudienceKicked((data) {
      Map<String, dynamic> info = data;
      if (info['sessionId'] == widget.sessionId) {
        Utils.showSnackbar(context, "You have been kicked by host.");
        Navigator.pop(context);
      }
    });

    SocketService.instance.onAudienceMuted((data) {
      Map<String, dynamic> info = data;
      if (info['sessionId'] == widget.sessionId) {
        setState(() {
          Utils.showSnackbar(context, "You have been Muted by host.");
          isMuted = true;
        });
      }
    });
    SocketService.instance.onAudienceUnMute((data) {
      Map<String, dynamic> info = data;
      if (info['sessionId'] == widget.sessionId) {
        setState(() {
          Utils.showSnackbar(context, "You have been UnMuted by host.");
          isMuted = false;
        });
      }
    });

    SocketService.instance.onParticipantLeft((participant) {
      setState(() {
        participants.removeWhere((p) => p.user.id == participant.user.id);
      });
    });

    // Add these listeners if not already:
    SocketService.instance.onAudienceJoined((audience) {
      // Handle audience join if needed
    });

    SocketService.instance.onAudienceLeft((audience) {
      // Handle audience left if needed
    });

    SocketService.instance.onLiveEnded((session) {
      Utils.showSnackbar(context, "The Live Ended!");
      Navigator.pop(context);
    });

    SocketService.instance.onSessionUpdated((session) {
      // Update your session data if needed
      setState(() {
        viewerCount = session.audience.length;
        participants.addAll(session.participants);
        list = [
          ...session.audience.where((u) => u.user.vipStatus),
          ...session.audience.where((u) => !u.user.vipStatus),
        ];
      });
    });

    SocketService.instance.onGiftReceived((gift1) async {
      final gift = Gift.fromJson(gift1['gift']);
      final fromUser = UserProfile.fromJson(gift1['fromUser']);
      final toUser = UserProfile.fromJson(gift1['toUser']);

      final url = Variables.BASE_URL + gift.imageUrl;
      final videoItem = await Utils.getCachedSvga(
        url,
      ); // Use cached loader here
      if (!mounted || videoItem == null) return;

      setState(() {
        _svgaController!.videoItem = videoItem;
        _showGiftAnimation = true;
        _giftSenderName = fromUser.name;
        _giftReceiverName = toUser.name;
        _giftAmount = gift.price;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _svgaController!.reset();
        _svgaController!.repeat(count: 1).whenComplete(() {
          if (!mounted) return;
          setState(() => _showGiftAnimation = false);
        });
      });
    });
  }

  @override
  void dispose() {
    SocketService.instance.leaveLive();
    _chatController.dispose();
    _svgaController?.dispose();
    participants.clear();
    viewerCount = 0;
    super.dispose();
  }

  void _sendComment() {
    if (isMuted) {
      Utils.showToast("You are muted by host.");
      return;
    }
    final msg = _chatController.text.trim();
    if (msg.isNotEmpty) {
      SocketService.instance.sendComment(msg);
      _chatController.clear();
    }
  }

  Widget _buildStreamGrid() {
    final mainStreamUrl = "${Variables.RTMP_URL}/${widget.hostUserId}";

    // If no participants, show only host
    if (participants.isEmpty) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ParticipantVideoWidget(streamUrl: mainStreamUrl),
      );
    }

    String hostUserId = widget.hostUserId;
    String participantId = participants.first.user.id;
    UserProfile hostProfile = widget.liveSession.hosts.first.user;
    UserProfile participantProfile = participants.first.user;
    String sessionId = widget.sessionId;

    // --- Top Row: Host + Self ---
    final topRow = Row(
      children: [
        // Host
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Utils.getParticipant(
                context,
                hostUserId,
                hostProfile,
                sessionId,
              ),
            ),
          ),
        ),

        // Self
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.0),
              child: Utils.getParticipant(
                context,
                participantId,
                participantProfile,
                sessionId,
              ),
            ),
          ),
        ),
      ],
    );

    // --- Guest participants: 3rd to 6th only ---
    final guestParticipants = participants.skip(1).take(4).toList();
    if (guestParticipants.isNotEmpty) {
      isParticipantAvail = true;
    } else {
      isParticipantAvail = false;
    }

    final guestRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        if (index < guestParticipants.length) {
          final p = guestParticipants[index];
          final userId = p.user.id;
          final UserProfile userProfile = p.user;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: Utils.getParticipant(
                    context,
                    userId,
                    userProfile,
                    sessionId,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Return empty space (invisible) for unused slots
          return const Expanded(child: SizedBox.shrink());
        }
      }),
    );

    return Column(
      children: [
        topRow,
        const SizedBox(height: 8),
        guestParticipants.isNotEmpty ? guestRow : const SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Always wrap stream in Positioned.fill
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0, -1),
              child: Padding(
                padding: const EdgeInsets.only(top: 100),
                child: _buildStreamGrid(),
              ),
            ),
          ),

          // Streamer name + close button
          Positioned(
            top: 20,
            left: 4,
            right: 4,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /// Host profile picture
                  CachedCircleAvatar(
                    imageUrl: widget.liveSession.hosts.first.user.profilePic,
                    user: widget.liveSession.hosts.first.user.settings,
                    radius: 20,
                  ),

                  const SizedBox(width: 4),

                  /// Name + viewer count + horizontal list
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Name + viewer count (same row)
                        Row(
                          children: [
                            Text(
                              widget.liveSession.hosts.first.user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                              "$viewerCount viewers",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        /// Horizontal VIP-first ListView
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
                                width: 28,
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

                  /// Close button
                  InkWell(
                    onTap: () {
                      SocketService.instance.audienceLeave();
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  InkWell(
                    onTap: () => {
                      Utils.showReportDialog(context, widget.hostUserId),
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.report, color: Colors.white, size: 20),
                    ),
                  ),
                ],
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
                                alpha: (0.5 * 255).toDouble(),
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
                                  const TextSpan(
                                    text: ' worth ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '\n$_giftAmount 💎', // second line
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
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

          // Comment list
          if (showCommentList)
            Positioned(
              left: 0,
              bottom: keyboardHeight + 60,
              height: isParticipantAvail
                  ? MediaQuery.of(context).size.height * 0.2
                  : MediaQuery.of(context).size.height * 0.3,
              width: MediaQuery.of(context).size.width * 0.8,
              child: CommentList(comments: comments),
            ),

          // Controls Panel
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
                  color: Colors.black.withValues(alpha: (0.5 * 255).toDouble()),
                  border: Border.all(color: Colors.white70, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        SocketService.instance.requestToJoin(
                          SocketService.instance.userId,
                          widget.hostUserId,
                        );
                      }, // Add gift logic here
                      icon: const Icon(Icons.join_full, color: Colors.white),
                      tooltip: "Request to join",
                    ),
                  ],
                ),
              ),
            ),

          // Chat input row
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
                    onPressed: () {
                      Utils.showGiftDialog(
                        context,
                        widget.hostUserId,
                        widget.sessionId,
                      );
                    },
                    icon: Icon(
                      Icons.wallet_giftcard,
                      color: Colors.white,
                      size: 30,
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
