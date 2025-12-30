import 'dart:math';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svga/flutter_svga.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/comment_list.dart';
import 'package:livekit_client/livekit_client.dart';

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

  String _giftSenderName = "";
  String _giftReceiverName = "";
  int _giftAmount = 0;
  List<LiveUser> list = [];
  bool isMuted = false;
  bool showCommentList = true;
  bool showControlsPanel = false;

  int viewerCount = 0;

  // LiveKit variables
  late Room _room;
  late EventsListener<RoomEvent> _roomListener;

  // Store remote participants and their video tracks
  final List<RemoteParticipant> _remoteParticipants = [];
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  // Store host's participant separately for easy access
  RemoteParticipant? _hostParticipant;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);

    // Initialize LiveKit room
    _room = Room();

    // Join audience and set up WebRTC
    _initializeAudienceConnection();

    // Set up socket listeners
    _setupSocketListeners();
  }

  void _initializeAudienceConnection() {
    // Join audience via socket
    SocketService.instance.joinAudience(widget.sessionId);

    // Listen for WebRTC token from server
    SocketService.instance.onWebRTCResponse((data) {
      _connectAsAudience(data.url, data.token);
    });
  }

  Future<void> _connectAsAudience(String url, String token) async {
    try {
      debugPrint('Connecting to LiveKit as audience: $url');

      // Set up listeners BEFORE connecting
      _setupRoomListeners();

      await _room.connect(
        url,
        token,
        roomOptions: RoomOptions(adaptiveStream: true, dynacast: true),
      );

      debugPrint('Audience connected to LiveKit room');
    } catch (e) {
      debugPrint('Failed to connect as audience: $e');
      Utils.showSnackbar(context, "Failed to connect to stream: $e");
    }
  }

  void _setupRoomListeners() {
    _roomListener = _room.createListener();

    // Track which participants we've already set up listeners for
    final Set<String> _listenedParticipantSids = {};

    _roomListener
      ..on<RoomConnectedEvent>((event) {
        debugPrint('Audience connected to room');
        _listenedParticipantSids.clear(); // Clear on new connection

        // Add existing remote participants
        for (final participant in _room.remoteParticipants.values) {
          _addParticipantWithListener(participant, _listenedParticipantSids);
        }
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Audience disconnected from room');
        if (mounted) {
          setState(() {
            _remoteParticipants.clear();
            _remoteVideoTracks.clear();
            _hostParticipant = null;
          });
        }
        _listenedParticipantSids.clear();
      })
      ..on<ParticipantConnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant connected: ${participant.identity}');

        _addParticipantWithListener(participant, _listenedParticipantSids);
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant disconnected: ${participant.identity}');

        // Remove from tracked lists
        _listenedParticipantSids.remove(participant.sid);

        setState(() {
          _remoteParticipants.remove(participant);
          _remoteVideoTracks.remove(participant.sid);

          if (participant.identity.toString() == widget.hostUserId.toString()) {
            _hostParticipant = null;
          }
        });
      })
      ..on<TrackSubscribedEvent>((event) {
        debugPrint('TrackSubscribedEvent: ${event.track.kind}');
        debugPrint('Track SID: ${event.track.sid}');
        debugPrint('From participant: ${event.participant.identity}');

        final track = event.track;
        final participant = event.participant;

        if (track.kind == TrackType.VIDEO) {
          setState(() {
            _remoteVideoTracks[participant.sid] = track as VideoTrack;
          });
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        debugPrint('Track unsubscribed: ${event.track.kind}');

        final track = event.track;
        final participant = event.participant;

        if (track.kind == TrackType.VIDEO) {
          setState(() {
            _remoteVideoTracks.remove(participant.sid);
          });
        }
      });
  }

// Helper method to avoid duplicate listener setup
  void _addParticipantWithListener(RemoteParticipant participant, Set<String> listenedSids) {
    // Check if we already have a listener for this participant
    if (listenedSids.contains(participant.sid)) {
      debugPrint('Already listening to participant: ${participant.identity} (sid: ${participant.sid})');
      return;
    }

    setState(() {
      _remoteParticipants.add(participant);
    });

    // Check if this is the host
    if (participant.identity.toString() == widget.hostUserId.toString()) {
      setState(() {
        _hostParticipant = participant;
      });
    }

    // Add listener only once
    participant.addListener(() {
      _onParticipantUpdate(participant);
    });

    // Mark this participant as having a listener
    listenedSids.add(participant.sid);

    debugPrint('Added listener for participant: ${participant.identity} (sid: ${participant.sid})');
  }

  void _onParticipantUpdate(Participant participant) {
    if (!mounted) return;
    setState(() {});
  }

  void _setupSocketListeners() {
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

    SocketService.instance.onAudienceKicked((data) {
      Map<String, dynamic> info = data;
      if (info['sessionId'] == widget.sessionId) {
        Utils.showSnackbar(context, "You have been kicked by host.");
        _cleanupAndExit();
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

    SocketService.instance.onLiveEnded((session) {
      Utils.showSnackbar(context, "The Live Ended!");
      _cleanupAndExit();
    });

    SocketService.instance.onSessionUpdated((session) {
      setState(() {
        viewerCount = session.audience.length;
        final existingIds = participants.map((p) => p.user.id).toSet();

        participants.addAll(
          session.participants.where(
                (p) => !existingIds.contains(p.user.id),
          ),
        );
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
      final videoItem = await Utils.getCachedSvga(url);
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

  void _cleanupAndExit() {
    _roomListener.dispose();
    _room.disconnect();

    if (mounted) {
      Navigator.pop(context);
    }
  }


  @override
  void dispose() {
    _roomListener.dispose();

    // Clean up all participant listeners
    for (final participant in _remoteParticipants) {
      // Note: LiveKit might handle this automatically, but we'll clear our references
    }

    if (_room.connectionState == ConnectionState.connected) {
      _room.disconnect();
    }
    _room.dispose();

    SocketService.instance.leaveLive();

    _chatController.dispose();
    _svgaController?.dispose();

    _remoteParticipants.clear();
    _remoteVideoTracks.clear();
    _hostParticipant = null;
    participants.clear();
    viewerCount = 0;

    super.dispose();
  }


  void _sendComment(String s) {
    if (isMuted) {
      Utils.showToast("You are muted by host.");
      return;
    }
    SocketService.instance.sendComment(s);
    _chatController.clear();
  }

  Widget _buildVideoWidget(String participantSid,String? id, bool showOption) {
    final track = _remoteVideoTracks[participantSid];
    LiveUser liveUser;
    if(id!=null){
      liveUser = participants.firstWhere(
            (p) => p.user.id == id,
      );
    }else{
      liveUser = widget.liveSession.hosts.first;
    }
    if (track == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.person, color: Colors.white54)),
      );
    }

    return Stack(
      children: [
        // Base video
        GestureDetector(
          onTap: () {
            Utils.showGiftDialog(
                context,
                liveUser.user.name,
                liveUser.userId,
                widget.sessionId,
                    (gift,toUserID){
                  _sendComment("${Variables.currentUser!.name} sent a gift to ${liveUser.user.name} worth ${gift.price}💎");
                }
            );
          },
          child: VideoTrackRenderer(track),
        ),

        // Overlay when participant is added
        if (showOption)
          Positioned(
            top: 2,
            left: 2,
            child: Row(
              children: [
                CachedCircleAvatar(imageUrl: liveUser.user.profilePic, user: liveUser.user.settings),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    liveUser.user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStreamGrid() {
    final videoParticipants = _remoteParticipants
        .where((p) => _remoteVideoTracks.containsKey(p.sid))
        .toList();

    final hostParticipant = _hostParticipant != null &&
        _remoteVideoTracks.containsKey(_hostParticipant!.sid)
        ? _hostParticipant
        : null;

    final otherParticipants = videoParticipants
        .where((p) => p != hostParticipant)
        .toList();

    if (videoParticipants.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text(
                "Connecting to stream...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (videoParticipants.length == 1 && hostParticipant != null) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildVideoWidget(hostParticipant.sid,null, false ),
        ),
      );
    }

    final topRow = Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hostParticipant != null
                  ? _buildVideoWidget(hostParticipant.sid,null,true)
                  : Container(
                color: Colors.grey[900],
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white54),
                ),
              ),
            ),
          ),
        ),

        if (otherParticipants.isNotEmpty)
          Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildVideoWidget(otherParticipants.first.sid,otherParticipants.first.identity,true),
              ),
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );

    final remainingParticipants = otherParticipants.length > 1
        ? otherParticipants.sublist(1, min(5, otherParticipants.length))
        : [];

    final bottomRow = remainingParticipants.isNotEmpty
        ? Row(
      children: List.generate(4, (index) {
        if (index < remainingParticipants.length) {
          final participant = remainingParticipants[index];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildVideoWidget(participant.sid,participant.identity,true),
                ),
              ),
            ),
          );
        } else {
          return const Expanded(child: SizedBox.shrink());
        }
      }),
    )
        : const SizedBox.shrink();

    if (remainingParticipants.isNotEmpty && !isParticipantAvail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isParticipantAvail = true;
        });
      });
    }

    return Column(
      children: [
        topRow,
        if (remainingParticipants.isNotEmpty) const SizedBox(height: 8),
        bottomRow,
      ],
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
                  padding: const EdgeInsets.only(top: 80),
                  child: _buildStreamGrid(),
                ),
              ),
            ),
        
            Positioned(
              top: 0,
              left: 4,
              right: 4,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CachedCircleAvatar(
                      imageUrl: widget.liveSession.hosts.first.user.profilePic,
                      user: widget.liveSession.hosts.first.user.settings,
                      radius: 20,
                    ),

        
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
        
                    InkWell(
                      onTap: _cleanupAndExit,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                    InkWell(
                      onTap: () => Utils.showReportDialog(context, widget.hostUserId),
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
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: SVGAImage(_svgaController!),
                        ),
        
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
                                      text: '\n$_giftAmount 💎',
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
                          Utils.showSnackbar(
                            context,
                            "Request sent to join as participant",
                          );
                        },
                        icon: const Icon(Icons.call, color: Colors.white),
                        tooltip: "Request to join",
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
                        onSubmitted: (_) {
                          final msg = _chatController.text.trim();
                          if(msg.isNotEmpty) {
                            _sendComment(msg);
                          }

                        } ,
                      ),
                    ),
                    IconButton(
                      onPressed: (){
                        final msg = _chatController.text.trim();
                        if(msg.isNotEmpty) {
                          _sendComment(msg);
                       }
                      },
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
                          widget.liveSession.hosts.first.user.name,
                          widget.hostUserId,
                          widget.sessionId,
                            (gift,toUserID){
                              _sendComment("${Variables.currentUser!.name} sent a gift to ${widget.liveSession.hosts.first.user.name} worth ${gift.price}💎");
                            }
                        );
                      },
                      icon: const Icon(
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
      ),
    );
  }
}