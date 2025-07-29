
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/scheduler/ticker.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:probashi_live/models/live_gift.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/participant_video_widget.dart';
import 'package:svgaplayer_flutter/parser.dart';
import 'package:svgaplayer_flutter/player.dart';

import '../models/gift.dart';
import '../models/live_comment.dart';
import '../models/live_user.dart';
import '../models/user_profile.dart';
import '../utils/api_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';
import 'cached_circle_avatar.dart';
import 'gift_dialog.dart';
import 'mini_user_profile_dialog.dart';
import 'one_to_one_chat.dart';

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

class _AudiencePageState extends State<AudiencePage> with TickerProviderStateMixin {
  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  final List<LiveUser> participants = [];

  late VlcPlayerController _mainStreamController;


  SVGAAnimationController? _svgaController;
  bool _showGiftAnimation = false;

  String _giftSenderName = "";  // store sender username
  String _giftReceiverName = "";


  bool showCommentList = true;
  bool showControlsPanel = false;

  int viewerCount = 0;

  void showGiftDialog() {
    showDialog(
      context: context,
      builder: (_) => GiftDialog(onGiftClick: (gift){
        sendGift(gift);
      },),
    );
  }


  @override
  void initState() {
    super.initState();

    final mainStreamUrl = "${Variables.RTMP_URL}/${widget.hostUserId}";
    _mainStreamController = VlcPlayerController.network(
      mainStreamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );

    _svgaController = SVGAAnimationController(vsync: this);
    SocketService.instance.joinAudience(widget.sessionId);

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
      Utils.showToast(context, "The Live Ended!");
      Navigator.pop(context);
    });

    SocketService.instance.onSessionUpdated((session) {
      // Update your session data if needed
      setState(() {
        viewerCount = session.audience.length;
      });
    });

    SocketService.instance.onGiftReceived((gift1) async {
      final gift = Gift.fromJson(gift1['gift']);
      final fromUser = UserProfile.fromJson(gift1['fromUser']);
      final toUser = UserProfile.fromJson(gift1['toUser']);

      final url = Variables.BASE_URL + gift.imageUrl;
      final videoItem = await Utils.getCachedSvga(url); // Use cached loader here
      if (!mounted || videoItem == null) return;

      setState(() {
        _svgaController!.videoItem = videoItem;
        _showGiftAnimation = true;
        _giftSenderName = fromUser.name;
        _giftReceiverName = toUser.name;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _svgaController!
            .reset();
        _svgaController!
            .repeat(count: 1)
            .whenComplete(() {
          if (!mounted) return;
          setState(() => _showGiftAnimation = false);
        });
      });
    });

  }

  @override
  void dispose() {
    SocketService.instance.leaveLive();
    _mainStreamController.stop();
    _mainStreamController.dispose();
    _chatController.dispose();
    _svgaController?.dispose();
    super.dispose();
  }

  void _sendComment() {
    final msg = _chatController.text.trim();
    if (msg.isNotEmpty) {
      SocketService.instance.sendComment(msg);
      _chatController.clear();
    }
  }
  
  void sendGift(Gift gift){
    LiveGift liveGift = LiveGift(toUserId: widget.hostUserId, sessionId: widget.sessionId, giftId: gift.id);
    SocketService.instance.sendGift(liveGift);
  }

  Widget _buildStreamGrid() {
    List<Widget> videoWidgets = [
      AspectRatio(
        aspectRatio: 9 / 16,
        child: VlcPlayer(
          controller: _mainStreamController,
          aspectRatio: 9 / 16,
          placeholder: const Center(child: CircularProgressIndicator()),
        ),
      ),
    ];

    videoWidgets.addAll(
      participants.map((p) {
        final streamUrl = "${Variables.RTMP_URL}/${p.user.id}";
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: ParticipantVideoWidget(streamUrl: streamUrl),
        );
      }).toList(),
    );

    if (videoWidgets.length == 1) {
      return videoWidgets.first;
    }

    return GridView.count(
      crossAxisCount: videoWidgets.length <= 2 ? 2 : 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: videoWidgets,
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
          Positioned.fill(child: _buildStreamGrid()),

          // Streamer name + close button
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () async {
                    final tappedUserId = widget.hostUserId;

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
                  child:
                  CachedCircleAvatar(imageUrl: widget.liveSession.hosts.first.user.profilePic, radius: 20,),

                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.liveSession.hosts.first.user.name,
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
                  onPressed:()=> Navigator.pop(context),
                ),
              ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
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

          // Comment list
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
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      // placeholder bg color
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Profile picture
                        GestureDetector(
                          onTap: () async {
                            if (c.liveUser.user.id !=
                                SocketService.instance.userId) {

                              Utils.printGreenComment(c.liveUser.user.toJson().toString());

                              if (c.liveUser.user.id == SocketService.instance.userId) return;

                              UserStats state = await ApiService.getApiClient().getUserStats(c.liveUser.user.id);
                              c.liveUser.user.stats = state;

                              UserProfile profile = await ApiService.getApiClient().getUserProfile(c.liveUser.user.id);
                              UserStats states = await ApiService.getApiClient().getUserStats(c.liveUser.user.id);
                              profile.stats = states;

                              _showMiniProfileDialog(profile);
                            }
                          },
                          child:
                          CachedCircleAvatar(imageUrl:  c.liveUser.user.profilePic,radius: 16,),


                        ),
                        const SizedBox(width: 8),

                        // Username + message as two lines
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${c.liveUser.user.name}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.message,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
                  color: Colors.black.withOpacity(0.5),
                  border: Border.all(color: Colors.white70, width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {}, // Add gift logic here
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
                    onPressed: showGiftDialog,
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

  void _showMiniProfileDialog(UserProfile userProfile) {
    // Optionally prevent showing own profile
    if (userProfile.id == SocketService.instance.userId) return;

    Utils.printGreenComment(userProfile.toJson().toString());

    showDialog(
      context: context,
      builder: (context) => MiniUserProfileDialog(
        userProfile: userProfile,
        onRelationToggle: () async {
          try {
            final newRelation = await Utils.toggleFollowStatus(userProfile);
            return newRelation;
          } catch (e) {
            print(e);
            return UserRelation(isFollowing: false, isFriend: false);
          }
        },
        onMessage: () {
          Navigator.pop(context);
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
