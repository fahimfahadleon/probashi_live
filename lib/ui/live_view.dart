import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/comment_list.dart';
import 'package:probashi_live/ui/participant_video_widget.dart';
import 'package:svgaplayer_flutter/player.dart';

import '../models/friend_user_model.dart';
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

class LivePage extends StatefulWidget {
  const LivePage({super.key});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> with TickerProviderStateMixin {
  bool isStreaming = false;
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isFrontCamera = true;
  bool _dialogShown = false;
  bool showControlsPanel = false;
  bool showCommentList = true;
  bool hasNotification = false;
  bool hasNotification1 = false;
  late LiveSession session;
  bool isBeautyEnabled = false;
  late String liveName = "default name";

  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  final List<LiveUser> participants = [];
  final List<UserProfile> users = [];
  int viewerCount = 0;
  late String profilePicture =
      "https://api.dicebear.com/7.x/identicon/png?seed=default";

  SVGAAnimationController? _svgaController;
  bool _showGiftAnimation = false;
  String _giftSenderName = '';
  String _giftReceiverName = '';

  @override
  void initState() {
    super.initState();


    PermissionService.requestPermission(
      context,
      onGranted: () {

        GenericStreamService.initialize();


        _svgaController = SVGAAnimationController(vsync: this);

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
        SocketService.instance.onParticipantJoined((participant) {
          // setState(() => participants.add(participant));
        });
        SocketService.instance.onParticipantLeft((participant) {
          setState(() {
            participants.removeWhere((p) => p.user.id == participant.user.id);
          });
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
                  participants.every((p) => updated.any((u) => u.user.id == p.user.id));

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

        SocketService.instance.onFriendListCalled((friendList) {
          showFriendInviteDialog(context, friendList);
        });

        SocketService.instance.onAudienceRequested((data){
          final exists = users.any((user) => user.id == data.id);
          if (!exists) {
            users.add(data);
            setState(() {
              hasNotification = true;
              hasNotification1 = true;
            });
          }
        });



        SocketService.instance.onInviteAccepted((data) {});
        SocketService.instance.onInviteCanceled((data) {
          Utils.showToast(context, "Invite canceled");
        });
      },
      onDenied: () {
        Utils.showToast(context, "Permission Denied");
        Navigator.pop(context);
      },
    );

  }

  void showFriendInviteDialog(
    BuildContext context,
    List<FriendUserModel> friendList,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite a Friend'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: friendList.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final friend = friendList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Profile picture
                    CachedCircleAvatar(
                      imageUrl: friend.profilePic,
                      radius: 10,
                      user: friend.settings,
                    ),
                    const SizedBox(width: 12),

                    // Name (takes available space)
                    Expanded(
                      child: Text(
                        friend.name,
                        style: const TextStyle(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // VIP + Invite icon group
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (friend.vipStatus)
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                        IconButton(
                          icon: const Icon(
                            Icons.person_add_alt_1,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            SocketService.instance.inviteToJoinLive(
                              fromUserId: SocketService.instance.userId,
                              toUserId: friend.id,
                              sessionId: session.id,
                            );
                            Navigator.pop(context);
                            Utils.showToast(
                              context,
                              "Invite sent to ${friend.name}",
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
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
      GenericStreamService.startStream(rtmpUrl);
      // GenericStreamService.switchCamera();
      SocketService.instance.goLive();
      setState(() => isStreaming = true);
    } else {
      Navigator.of(context).pop();
    }
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
    GenericStreamService.toggleCamera();
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
    SocketService.instance.getFriends();
  }

  void startPreview() async {
    GenericStreamService.startPreview();
    await Future.delayed(Duration(milliseconds: 200));
    // Do something after 200ms
  }

  Widget buildAndroidPlatformView() {
    return PlatformViewLink(
      viewType: 'generic_stream_view',
      surfaceFactory: (context, controller) {
        return AndroidViewSurface(
          controller: controller as AndroidViewController,
          gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
        );
      },
      onCreatePlatformView: (params) {
        return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'generic_stream_view',
            layoutDirection: TextDirection.ltr,
            creationParams: {},
            creationParamsCodec: const StandardMessageCodec(),
          )
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..create();
      },
    );
  }

  Widget _buildStreamGrid() {
    if (participants.isEmpty) {
      return buildAndroidPlatformView();
    }

    final String hostId = session.hosts.first.user.id;

    // Host AndroidView (left side)
    final hostView = Expanded(
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: buildAndroidPlatformView(),
        ),
      ),
    );

    // First non-host participant (right side)
    final firstParticipant = participants.firstWhere(
      (p) => p.user.id != hostId,
    );

    final participantVLCView = firstParticipant != null
        ? Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: ParticipantVideoWidget(
                  streamUrl:
                      "${Variables.RTMP_URL}/${firstParticipant.user.id}",
                ),
              ),
            ),
          )
        : const Expanded(child: SizedBox.shrink());

    final topRow = Row(children: [hostView, participantVLCView]);

    // Remaining participants after first
    final remainingParticipants = participants
        .where((p) => p.user.id != hostId && p != firstParticipant)
        .take(4)
        .toList();

    // Guest row with up to 4 VLC participants, and empty slots if needed
    final guestRow = Row(
      children: List.generate(4, (index) {
        if (index < remainingParticipants.length) {
          final userId = remainingParticipants[index].user.id;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: ParticipantVideoWidget(
                    streamUrl: "${Variables.RTMP_URL}/$userId",
                  ),
                ),
              ),
            ),
          );
        } else {
          // Invisible slot (no placeholder)
          return const Expanded(child: SizedBox.shrink());
        }
      }),
    );

    return Column(
      children: [
        topRow,
        const SizedBox(height: 8),
        remainingParticipants.isNotEmpty ? guestRow : const SizedBox.shrink(),
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
      SocketService.instance.leaveLive();
    }
    super.dispose();
  }


  void showRequestsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "User Requests",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),

                // User list
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 6),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        leading: CachedCircleAvatar(
                          imageUrl: user.profilePic,
                          radius: 16,
                          user: user.settings,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.diamond, size: 12, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text("${user.diamond}", style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () {

                                users.remove(user);
                                SocketService.instance.joinRequestAccepted(user);

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Accepted ${user.name}")),
                                );
                              },
                            ),

                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Deleted ${user.name}")),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                // Close button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -1),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50),
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
                top: 20,
                left: 16,
                right: 16,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    // Vertically center everything
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final tappedUserId = session.hosts.first.userId;
                          if (tappedUserId == SocketService.instance.userId) {
                            return;
                          }
                          try {
                            UserStats stats = await ApiService.getApiClient().getUserStats(tappedUserId);
                            UserProfile profile =
                                await ApiService.getApiClient().getUserProfile(
                                  tappedUserId,
                                );
                            profile.stats = stats;
                            Utils.showMiniProfileDialog(profile, context);
                          } catch (e) {
                            print("Error loading profile: $e");
                          }
                        },
                        child: CachedCircleAvatar(
                          imageUrl: profilePicture,
                          user: Variables.currentUser?.settings,
                          radius: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          // Prevent vertical stretch
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
              ),
              if (showCommentList)
                Positioned(
                  left: 0,
                  bottom: keyboardHeight + 60,
                  height: MediaQuery.of(context).size.height * 0.3,
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: CommentList(
                    comments: comments,
                    isHost: true,
                    onMuteUser: (s) => _muteUser(s),
                    onKickUser: (s) => _kickUser(s),
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
                        // IconButton(
                        //   onPressed: participants.length < 5
                        //       ? _inviteParticipant
                        //       : null,
                        //   icon: const Icon(
                        //     Icons.group_add,
                        //     color: Colors.white,
                        //   ),
                        //   tooltip: "Add People",
                        // ),
                        IconButton(
                            onPressed: (){
                              setState(() {
                                isBeautyEnabled = !isBeautyEnabled;
                              });
                              GenericStreamService.toggleBeauty();
                            },
                            icon: Icon(isBeautyEnabled?Icons.face_retouching_natural:Icons.face_outlined , color: Colors.white,)),
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  hasNotification = false;
                                });
                                showRequestsDialog(context);
                              },
                              icon: const Icon(
                                Icons.login,
                                color: Colors.white,
                              ),
                              tooltip: "Join Requests",
                            ),

                            // 🔴 Small red dot positioned at top-right
                            if (hasNotification)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        )
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                        onPressed:(){
                          setState(() {
                            hasNotification1 = false;
                          });
                          _toggleControlsPanel();
                        },
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              showControlsPanel
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.white,
                              size: 30,
                            ),
                            if (hasNotification1)
                              Positioned(
                                right: 0,
                                top: -1,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // IconButton(
                      //   onPressed: _toggleControlsPanel,
                      //   icon: Icon(
                      //     showControlsPanel
                      //         ? Icons.keyboard_arrow_down
                      //         : Icons.keyboard_arrow_up,
                      //     color: Colors.white,
                      //     size: 30,
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
