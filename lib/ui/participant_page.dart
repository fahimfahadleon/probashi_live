import 'dart:math';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/ui/comment_list.dart';
import 'package:livekit_client/livekit_client.dart';

import '../models/gift.dart';
import '../models/user_profile.dart';
import '../services/generic_system_service.dart';
import '../utils/api_service.dart';
import '../utils/permission_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';

import '../models/live_comment.dart';
import '../models/live_user.dart';
import '../models/webrtc_response.dart';
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

  // LiveKit variables
  late Room _room;
  late EventsListener<RoomEvent> _roomListener;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  // Remote participants
  final List<RemoteParticipant> _remoteParticipants = [];
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  // Store host's participant separately
  RemoteParticipant? _hostParticipant;

  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  late List<LiveUser> participants = [];
  int viewerCount = 0;
  List<LiveUser> list = [];
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
        _svgaController = SVGAAnimationController(vsync: this);

        // Initialize LiveKit room
        _room = Room();

        // Accept invite and set up WebRTC
        SocketService.instance.acceptInvite(
          fromUserId: widget.from,
          userId: widget.to,
          sessionId: widget.sessionId,
        );

        // Request session details
        SocketService.instance.requestLiveSessionDetails(widget.sessionId);

        // Listen for WebRTC token response
        SocketService.instance.onWebRTCResponse((data) {
          if (data is WebRTCResponse) {
            // Connect as participant (can publish and subscribe)
            _connectAsParticipant(data.url, data.token);
          }
        });

        SocketService.instance.onGiftReceived((gift1) async {
          final gift = Gift.fromJson(gift1['gift']);
          final fromUser = UserProfile.fromJson(gift1['fromUser']);
          final toUser = UserProfile.fromJson(gift1['toUser']);

          if(toUser.id == Variables.currentUser!.id){
            Utils.updateProfile();
          }

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
            liveName = session.hosts.first.user.name;
            profilePicture = session.hosts.first.user.profilePic;
            isSessionLoaded = true;

            // Store host user ID for later comparison
            _hostUserId = session.hosts.first.user.id;
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

        SocketService.instance.onSessionUpdated((updatedSession) {
          setState(() {
            session = updatedSession;
            viewerCount = updatedSession.audience.length;
            list = [
              ...updatedSession.audience.where((u) => u.user.vipStatus),
              ...updatedSession.audience.where((u) => !u.user.vipStatus),
            ];

            // Clear and rebuild participants list to ensure it's in sync
            participants = updatedSession.participants;

            // IMPORTANT: Also add the host to participants if not already there
            // This ensures host is always in the list when needed
            if (!participants.any(
              (p) => p.user.id == updatedSession.hosts.first.user.id,
            )) {
              participants.add(updatedSession.hosts.first);
            }
          });
        });

        SocketService.instance.onLiveEnded((sessionData) {
          if (mounted) {
            _endStream();
            Utils.showSnackbar(context, "Live ended");
          }
        });
      },
      onDenied: () {
        SocketService.instance.cancelInvite(
          fromUserId: widget.from,
          toUserId: widget.to,
          sessionId: widget.sessionId,
        );
        Utils.showSnackbar(context, "Permission Denied");
        Navigator.pop(context);
      },
    );
  }

  String? _hostUserId;

  Future<void> _connectAsParticipant(String url, String token) async {
    try {
      debugPrint('Participant connecting to LiveKit: $url');

      // Set up listeners before connecting
      _setupRoomListeners();

      await _room.connect(
        url,
        token,
        roomOptions: RoomOptions(adaptiveStream: true, dynacast: true),
      );

      // Create and publish local tracks
      final options = CameraCaptureOptions(
        cameraPosition: isFrontCamera
            ? CameraPosition.front
            : CameraPosition.back,
        maxFrameRate: 30,
        stopCameraCaptureOnMute: true,
      );

      _localVideoTrack = await LocalVideoTrack.createCameraTrack(options);
      _localAudioTrack = await LocalAudioTrack.create();

      await _room.localParticipant?.publishVideoTrack(_localVideoTrack!);
      await _room.localParticipant?.publishAudioTrack(_localAudioTrack!);

      setState(() {
        isStreaming = true;
      });

      debugPrint('Participant connected and publishing successfully');
    } catch (e) {
      debugPrint('Failed to connect as participant: $e');
      Utils.showSnackbar(context, "Failed to join as participant: $e");
    }
  }

  void _setupRoomListeners() {
    _roomListener = _room.createListener();

    _roomListener
      ..on<RoomConnectedEvent>((event) {
        debugPrint('Participant connected to room');

        // Add existing remote participants
        for (final participant in _room.remoteParticipants.values) {
          if (participant is RemoteParticipant) {
            setState(() {
              _remoteParticipants.add(participant);
            });

            // Check if this is the host
            if (_hostUserId != null && participant.identity == _hostUserId) {
              setState(() {
                _hostParticipant = participant;
              });
            }

            participant.addListener(() {
              _onParticipantUpdate(participant);
            });
          }
        }
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Participant disconnected from room');
        if (mounted) {
          setState(() {
            isStreaming = false;
            _remoteParticipants.clear();
            _remoteVideoTracks.clear();
            _hostParticipant = null;
          });
        }
      })
      ..on<ParticipantConnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant joined: ${participant.identity}');

        if (participant is RemoteParticipant) {
          setState(() {
            _remoteParticipants.add(participant);
          });

          // Check if this is the host
          if (_hostUserId != null && participant.identity == _hostUserId) {
            setState(() {
              _hostParticipant = participant;
            });
          }

          participant.addListener(() {
            _onParticipantUpdate(participant);
          });
        }
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant left: ${participant.identity}');

        if (participant is RemoteParticipant) {
          setState(() {
            _remoteParticipants.remove(participant);
            _remoteVideoTracks.remove(participant.sid);

            if (participant.identity == _hostUserId) {
              _hostParticipant = null;
            }
          });
        }
      })
      ..on<TrackSubscribedEvent>((event) {
        final track = event.track;
        final participant = event.participant;

        if (track.kind == TrackType.VIDEO && participant is RemoteParticipant) {
          setState(() {
            _remoteVideoTracks[participant.sid] = track as VideoTrack;
          });
        }
      })
      ..on<TrackUnsubscribedEvent>((event) {
        final track = event.track;
        final participant = event.participant;

        if (track.kind == TrackType.VIDEO && participant is RemoteParticipant) {
          setState(() {
            _remoteVideoTracks.remove(participant.sid);
          });
        }
      });
  }

  void _onParticipantUpdate(Participant participant) {
    if (!mounted) return;
    setState(() {});
  }

  Widget _buildLocalVideo(bool participantAdded) {
    if (_localVideoTrack == null) {
      return Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        // Base video
        VideoTrackRenderer(_localVideoTrack!),

        // Overlay when participant is added
        if (participantAdded && Variables.currentUser != null)
          Positioned(
            top: 2,
            left: 2,
            child: Row(
              children: [
                CachedCircleAvatar(
                  imageUrl: Variables.currentUser!.profilePic,
                  user: Variables.currentUser!.settings,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    Variables.currentUser!.name,
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

  Widget _buildRemoteVideo(String participantSid, String? participantIdentity) {
    final track = _remoteVideoTracks[participantSid];

    // First, check if track exists
    if (track == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.person, color: Colors.white54)),
      );
    }

    // Try to find the participant in our local list
    LiveUser participant;

    if (participantIdentity != null) {
      if (participantIdentity == session.hosts.first.user.id) {
        participant = session.hosts.first;
      } else {
        try {
          participant = participants.firstWhere(
            (p) => p.user.id == participantIdentity,
          );
        } catch (e) {
          debugPrint(
            'Participant not found in local list: $participantIdentity',
          );
          return VideoTrackRenderer(track);
        }
      }
    } else {
      // If no identity provided, assume it's the host
      participant = session.hosts.first;
    }

    // If we found the participant, show overlay
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Utils.showGiftDialog(
              context,
              participant.user.name,
              participant.userId,
              session.id,
              (gift, string) {
                _sendComment(
                  "${Variables.currentUser!.name} sent a gift to ${participant.user.name} worth ${gift.price}💎",
                );
              },
            );
          },
          child: VideoTrackRenderer(track),
        ),

        Positioned(
          top: 2,
          left: 2,
          child: Row(
            children: [
              CachedCircleAvatar(
                imageUrl: participant.user.profilePic,
                user: participant.user.settings,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  participant.user.name,
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
    // Get all participants with video tracks
    final videoParticipants = _remoteParticipants
        .where((p) => _remoteVideoTracks.containsKey(p.sid))
        .toList();

    // Find host participant (if available)
    final hostParticipant =
        _hostParticipant != null &&
            _remoteVideoTracks.containsKey(_hostParticipant!.sid)
        ? _hostParticipant
        : null;

    // Get other participants (non-host)
    final otherParticipants = videoParticipants
        .where((p) => p != hostParticipant)
        .toList();

    // If no one else is streaming, show only local video
    if (videoParticipants.isEmpty) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildLocalVideo(false),
        ),
      );
    }

    // Build top row: host + self or first participant + self
    final topRow = Row(
      children: [
        // Host or first participant
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hostParticipant != null
                  ? _buildRemoteVideo(
                      hostParticipant.sid,
                      hostParticipant.identity,
                    )
                  : otherParticipants.isNotEmpty
                  ? _buildRemoteVideo(
                      otherParticipants.first.sid,
                      otherParticipants.first.identity,
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(
                        child: Icon(Icons.person, color: Colors.white54),
                      ),
                    ),
            ),
          ),
        ),

        // Self (local video)
        Expanded(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildLocalVideo(true),
            ),
          ),
        ),
      ],
    );

    // Get remaining participants (excluding the one already shown)
    final remainingParticipants =
        otherParticipants.isNotEmpty && hostParticipant == null
        ? otherParticipants.sublist(1, min(5, otherParticipants.length))
        : otherParticipants.sublist(0, min(4, otherParticipants.length));

    final bottomRow = remainingParticipants.isNotEmpty
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(4, (index) {
              if (index < remainingParticipants.length) {
                final participant = remainingParticipants[index];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildRemoteVideo(
                          participant.sid,
                          participant.identity,
                        ),
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

    // Update participant availability for comment list positioning
    if (remainingParticipants.isNotEmpty && !isParticipantAvail) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          isParticipantAvail = true;
        });
      });
    }

    return Column(children: [topRow, const SizedBox(height: 8), bottomRow]);
  }

  Future<bool> _confirmEndStream() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Leave Stream"),
        content: const Text("Are you sure you want to leave the stream?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Leave"),
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

  Future<void> _endStream() async {
    try {
      // Unpublish and stop local tracks
      if (_localVideoTrack != null) {
        await _room.localParticipant?.unpublishAllTracks();
        await _localVideoTrack!.stop();
        _localVideoTrack = null;
      }
      if (_localAudioTrack != null) {
        await _room.localParticipant?.unpublishAllTracks();
        await _localAudioTrack!.stop();
        _localAudioTrack = null;
      }

      // Disconnect room
      if (_room.connectionState == ConnectionState.connected) {
        await _room.disconnect();
      }

      // Clear UI state
      if (mounted) {
        setState(() {
          isStreaming = false;
          _remoteParticipants.clear();
          _remoteVideoTracks.clear();
          _hostParticipant = null;
        });

        // Notify server
        SocketService.instance.participantLeft();
      }
    } catch (e) {
      debugPrint('Error ending stream: $e');
    } finally {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _sendComment(String s) {
    SocketService.instance.sendComment(s);
    _chatController.clear();
  }

  Future<void> _toggleMic() async {
    if (_localAudioTrack != null) {
      try {
        setState(() {
          isMicOn = !isMicOn;
        });
        if (isMicOn) {
          await _localAudioTrack!.unmute(stopOnMute: false);
        } else {
          await _localAudioTrack!.mute(stopOnMute: false);
        }
      } catch (e) {
        debugPrint('Error toggling mic: $e');
      }
    }
  }

  Future<void> _toggleCamera() async {
    if (_localVideoTrack != null) {
      try {
        setState(() {
          isCameraOn = !isCameraOn;
        });
        if (isCameraOn) {
          await _localVideoTrack!.unmute(stopOnMute: false);
        } else {
          await _localVideoTrack!.mute(stopOnMute: false);
        }
      } catch (e) {
        debugPrint('Error toggling camera: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_localVideoTrack != null) {
      try {
        await _localVideoTrack!.switchCamera("");
        setState(() {
          isFrontCamera = !isFrontCamera;
        });
      } catch (e) {
        debugPrint('Error switching camera: $e');
      }
    }
  }

  void _toggleControlsPanel() {
    setState(() => showControlsPanel = !showControlsPanel);
  }

  @override
  void dispose() {
    _svgaController?.dispose();
    _chatController.dispose();

    // Clean up LiveKit
    _roomListener.dispose();
    if (_room.connectionState == ConnectionState.connected) {
      _room.disconnect();
    }
    _room.dispose();

    // Stop local tracks
    _localVideoTrack?.stop();
    _localAudioTrack?.stop();

    // Clear local state
    participants.clear();
    viewerCount = 0;

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
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final tappedUserId = session.hosts.first.userId;
                          if (tappedUserId == SocketService.instance.userId) {
                            return;
                          }
                          try {
                            final stats = await ApiService.getApiClient()
                                .getUserStats(tappedUserId);
                            final profile = await ApiService.getApiClient()
                                .getUserProfile(tappedUserId);
                            profile.stats = stats;
                            Utils.showMiniProfileDialog(
                              userProfile: profile,
                              context: context,
                            );
                          } catch (e) {
                            debugPrint("Error loading profile: $e");
                          }
                        },
                        child: CachedCircleAvatar(
                          imageUrl: profilePicture,
                          user: session.hosts.first.user.settings,
                          radius: 20,
                        ),
                      ),
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
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: _onClosePressed,
                        borderRadius: BorderRadius.circular(16),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
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
                          onSubmitted: (_) {
                            if (_chatController.text.isNotEmpty) {
                              _sendComment(_chatController.text.trim());
                            }
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_chatController.text.isNotEmpty) {
                            _sendComment(_chatController.text.trim());
                          }
                        },
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
      ),
    );
  }
}
