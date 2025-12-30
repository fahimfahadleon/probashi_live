import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_svga/flutter_svga.dart';
import 'package:probashi_live/models/live_session.dart';
import 'package:probashi_live/models/webrtc_response.dart';
import 'package:probashi_live/ui/comment_list.dart';

import '../models/gift.dart';
import '../models/user_profile.dart';
import '../services/generic_system_service.dart';
import '../utils/api_service.dart';
import '../utils/permission_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import '../utils/variables.dart';
import 'package:livekit_client/livekit_client.dart';

import '../models/live_comment.dart';
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
  late String liveName = "default name";
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;
  ConnectionQuality _connectionQuality = ConnectionQuality.unknown;

  final TextEditingController _chatController = TextEditingController();
  final List<LiveComment> comments = [];
  late List<LiveUser> participants = [];
  final List<UserProfile> users = [];
  int viewerCount = 0;
  late String profilePicture =
      "https://api.dicebear.com/7.x/identicon/png?seed=default";

  SVGAAnimationController? _svgaController;
  bool _showGiftAnimation = false;
  String _giftSenderName = '';
  String _giftReceiverName = '';
  bool isParticipantAvail = false;
  List<String> mutedUsers = [];
  List<LiveUser> list = [];
  late EventsListener<RoomEvent> _roomListener;

  // LiveKit variables
  late Room _room;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  // Remote participants - only those who are PUBLISHING video/audio
  final List<RemoteParticipant> _publishingParticipants = [];
  final Map<String, VideoTrack> _remoteVideoTracks = {};

  // All remote users (including audience - for tracking purposes only)
  final Map<String, RemoteParticipant> _allRemoteUsers = {};

  @override
  void initState() {
    super.initState();

    PermissionService.requestPermission(
      context,
      onGranted: () {
        _svgaController = SVGAAnimationController(vsync: this);
        _initializeLiveKit();

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
          debugPrint("sessionUpdate ${updatedSession.toJson().toString()}");
          // Simply replace the entire participants list
          setState(() {
            session = updatedSession;
            participants = updatedSession.participants; // Direct assignment
            viewerCount = updatedSession.audience.length;
            list = [
              ...updatedSession.audience.where((u) => u.user.vipStatus),
              ...updatedSession.audience.where((u) => !u.user.vipStatus),
            ];
          });
        });

        SocketService.instance.onLiveEnded((sessionData) {
          // if (mounted) {
          //   _endStream();
          // }
        });

        SocketService.instance.onLiveStarted((sessionData) {
          setState(() {
            session = sessionData.fullSession;
            liveName = sessionData.fullSession.hosts.first.user.name;
            profilePicture =
                sessionData.fullSession.hosts.first.user.profilePic;
          });
          _connectAsHost(sessionData.webrtc.url, sessionData.webrtc.token);
        });

        SocketService.instance.onWebRTCResponse((data) {
          WebRTCResponse response = data;
        });

        SocketService.instance.onAudienceRequested((data) {
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
          Utils.showSnackbar(context, "Invite canceled");
        });
      },
      onDenied: () {
        Utils.showSnackbar(context, "Permission Denied");
        Navigator.pop(context);
      },
    );
  }

  void _initializeLiveKit() {
    _room = Room();
  }

  Future<void> _connectAsHost(String url, String token) async {
    if (isStreaming || !mounted) {
      return;
    }

    try {
      // Show loading state
      setState(() {
        isStreaming = true; // Set true immediately to show loading UI
      });

      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        stopLocalTrackOnUnpublish: true,
      );
      // Connect to LiveKit room
      await _room.connect(url, token, roomOptions: roomOptions);

      // Check if we have permission and context still valid
      if (!mounted) return;

      // Create camera track with front camera by default
      final options = CameraCaptureOptions(
        cameraPosition: isFrontCamera
            ? CameraPosition.front
            : CameraPosition.back,
        maxFrameRate: 30,
        stopCameraCaptureOnMute: true,
      );

      _localVideoTrack = await LocalVideoTrack.createCameraTrack(options);
      _localAudioTrack = await LocalAudioTrack.create();

      // Publish tracks
      await _room.localParticipant?.publishVideoTrack(_localVideoTrack!);
      await _room.localParticipant?.publishAudioTrack(_localAudioTrack!);

      // Setup listeners after successful connection
      _setupParticipantListeners();

      debugPrint('WebRTC connected successfully');
    } catch (e) {
      debugPrint('Failed to connect: $e');
      if (mounted) {
        Utils.showSnackbar(context, "Failed to start stream: ${e.toString()}");
        setState(() {
          isStreaming = false;
        });
        // Consider going back if connection fails
        Navigator.of(context).pop();
      }
    }
  }

  void _setupParticipantListeners() {
    _roomListener = _room.createListener();
    final Set<String> listenedParticipantSids = {};

    _roomListener
      ..on<RoomConnectedEvent>((event) {
        debugPrint('Room connected: ${event.room.name}');
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Room disconnected: ${event.reason}');
        if (mounted) {
          setState(() {
            isStreaming = false;
            _publishingParticipants.clear();
            _remoteVideoTracks.clear();
            _allRemoteUsers.clear();
          });
        }
      })

      ..on<ParticipantConnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant connected: ${participant.identity}');

        // Store all remote users
        if (participant is RemoteParticipant) {
          _allRemoteUsers[participant.identity] = participant;

          // Only add listener if not already listening
          if (!listenedParticipantSids.contains(participant.sid)) {
            participant.addListener(() {
              _onParticipantUpdate(participant);
            });
            listenedParticipantSids.add(participant.sid);
          }
        }
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        final participant = event.participant;
        debugPrint('Participant disconnected: ${participant.identity}');

        setState(() {
          if (participant is RemoteParticipant) {
            listenedParticipantSids.remove(participant.sid);
            _allRemoteUsers.remove(participant.identity);
            _publishingParticipants.remove(participant);
            _remoteVideoTracks.remove(participant.sid);
          }
        });
      })

      ..on<TrackPublishedEvent>((event) {
        final participant = event.participant;
        final publication = event.publication;

        debugPrint(
          'Track published by ${participant.identity}: ${publication.kind}',
        );

        // When a participant publishes a track, add them to publishing list
        if (participant is RemoteParticipant &&
            !_publishingParticipants.contains(participant)) {
          setState(() {
            _publishingParticipants.add(participant);
          });
        }
      })
      ..on<TrackUnpublishedEvent>((event) {
        final participant = event.participant;
        final publication = event.publication;

        debugPrint(
          'Track unpublished by ${participant.identity}: ${publication.kind}',
        );

        // Check if participant still has any published tracks
        if (participant is RemoteParticipant) {
          final hasPublishedTracks =
              participant.videoTrackPublications.any((p) => p.track != null) ||
              participant.audioTrackPublications.any((p) => p.track != null);

          if (!hasPublishedTracks &&
              _publishingParticipants.contains(participant)) {
            setState(() {
              _publishingParticipants.remove(participant);
              _remoteVideoTracks.remove(participant.sid);
            });
          }
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
      })
      ..on<ParticipantConnectionQualityUpdatedEvent>((event) {
        setState(() {
          _connectionQuality = event.connectionQuality;
        });
      })
      ..on<RoomReconnectingEvent>((event) {
        if (mounted) {
          setState(() {
            _isReconnecting = true;
            _reconnectAttempts++;
          });

          if (_reconnectAttempts >= _maxReconnectAttempts) {
            _showReconnectFailedDialog();
          }
        }
      })
      ..on<RoomReconnectedEvent>((event) {
        if (mounted) {
          setState(() {
            _isReconnecting = false;
            _reconnectAttempts = 0;
          });
          Utils.showSnackbar(context, "Reconnected successfully");
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
        if (participantAdded)
          Positioned(
            top: 2,
            left: 2,
            child: Row(
              children: [
                CachedCircleAvatar(imageUrl: Variables.currentUser!.profilePic, user: Variables.currentUser!.settings),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  // Widget _buildRemoteVideo(String participantSid,String participantIdentity) {
  //   final track = _remoteVideoTracks[participantSid];
  //
  //   LiveUser? participant = participants.firstWhere(
  //         (p) => p.user.id == participantIdentity,
  //   );
  //
  //   if (track == null) {
  //     return Container(
  //       color: Colors.grey[900],
  //       child: const Center(child: Icon(Icons.person, color: Colors.white54)),
  //     );
  //   }
  //
  //
  //   return Stack(
  //     children: [
  //       // Base video
  //       VideoTrackRenderer(_localVideoTrack!),
  //
  //       // Overlay when participant is added
  //
  //       Positioned(
  //         top: 12,
  //         left: 12,
  //         child: Row(
  //           children: [
  //             CachedCircleAvatar(imageUrl: participant.user.profilePic, user: participant.user.settings),
  //             const SizedBox(width: 8),
  //             Container(
  //               padding:
  //               const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: Colors.black.withOpacity(0.6),
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Text(
  //                 participant.user.name,
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 12,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }
  //
  Widget _buildRemoteVideo(String participantSid, String participantIdentity) {
    final track = _remoteVideoTracks[participantSid];

    // Try to find participant in participants list
    LiveUser? participant;
    try {
      participant = participants.firstWhere(
            (p) => p.user.id == participantIdentity,
      );
    } catch (e) {
      debugPrint('Participant not found in list: $participantIdentity');
      // Fallback: just show video without overlay
      if (track == null) {
        return Container(
          color: Colors.grey[900],
          child: const Center(child: Icon(Icons.person, color: Colors.white54)),
        );
      }
      return VideoTrackRenderer(track);
    }

    if (track == null) {
      return Container(
        color: Colors.grey[900],
        child: const Center(child: Icon(Icons.person, color: Colors.white54)),
      );
    }

    return Stack(
      children: [
        // Base video - FIXED: use track, not _localVideoTrack!
        VideoTrackRenderer(track),

        // Overlay when participant is added
        Positioned(
          top: 2,
          left: 2,
          child: Row(
            children: [
              CachedCircleAvatar(
                  imageUrl: participant.user.profilePic,
                  user: participant.user.settings
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
    // Participants with video
    final videoParticipants = _publishingParticipants
        .where((p) => _remoteVideoTracks.containsKey(p.sid))
        .toList();

    debugPrint('Publishing participants with video: ${videoParticipants.length}');

    // No participants → host full screen (9:16)
    if (videoParticipants.isEmpty) {
      return AspectRatio(
        aspectRatio: 9 / 16,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildLocalVideo(false),
        ),
      );
    }

    // One participant → split screen (host + participant)
    if (videoParticipants.length == 1) {
      return Row(
        children: [
          Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildLocalVideo(true),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildRemoteVideo(videoParticipants.first.sid, videoParticipants.first.identity),
              ),
            ),
          ),
        ],
      );
    }

    // 2+ participants
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: host + first participant
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildLocalVideo(true),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildRemoteVideo(videoParticipants.first.sid, videoParticipants.first.identity),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Bottom row: remaining participants (scrollable)
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: videoParticipants.length - 1,
            itemBuilder: (context, index) {
              final participant = videoParticipants[index + 1];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < videoParticipants.length - 2 ? 4 : 0,
                ),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildRemoteVideo(participant.sid,participant.identity),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildConnectionStatus() {
    Color statusColor;
    String statusText;

    switch (_connectionQuality) {
      case ConnectionQuality.excellent:
        statusColor = Colors.green;
        statusText = 'Excellent';
      case ConnectionQuality.good:
        statusColor = Colors.lightGreen;
        statusText = 'Good';
      case ConnectionQuality.poor:
        statusColor = Colors.orange;
        statusText = 'Poor';
      default:
        statusColor = Colors.grey;
        statusText = 'Connecting...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _toggleMic() async {
    if (_localAudioTrack != null) {
      setState(() {
        isMicOn = !isMicOn;
      });
      if (isMicOn) {
        await _localAudioTrack!.unmute(stopOnMute: false);
      } else {
        await _localAudioTrack!.mute(stopOnMute: false);
      }
    }
  }

  void _toggleControlsPanel() {
    setState(() => showControlsPanel = !showControlsPanel);
  }

  void _toggleCamera() async {
    if (_localVideoTrack != null) {
      setState(() {
        isCameraOn = !isCameraOn;
      });
      if (isCameraOn) {
        await _localVideoTrack!.unmute(stopOnMute: false);
      } else {
        await _localVideoTrack!.mute(stopOnMute: false);
      }
    }
  }

  void _switchCamera() async {
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

  void _showReconnectFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Connection Lost"),
        content: const Text("Unable to reconnect to the stream."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.delayed(Duration.zero, () => _showStartLiveDialog());
    }
  }

  Future<void> _showStartLiveDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Start Live Stream?"),
        content: const Text("Do you want to go live now with WebRTC?"),
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
      // Request WebRTC session from server
      SocketService.instance.goLive();
      // The actual connection will happen in onLiveStarted callback
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
      try {
        await _endStream();
      } catch (e) {
        debugPrint('Error closing stream: $e');
      }
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

      // Clear UI state safely
      if (mounted) {
        setState(() {
          isStreaming = false;
          _publishingParticipants.clear();
          _remoteVideoTracks.clear();
          _allRemoteUsers.clear();
        });

        // Notify server
        SocketService.instance.leaveLive();

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error ending stream: $e');
    }
  }

  @override
  void dispose() {
    // Stop animation controller first
    _svgaController?.dispose();

    // Clean up chat controller
    _chatController.dispose();

    // Dispose room listener
    _roomListener.dispose();

    // Unpublish tracks
    if (_localVideoTrack != null) {
      _room.localParticipant?.unpublishAllTracks();
    }
    if (_localAudioTrack != null) {
      _room.localParticipant?.unpublishAllTracks();
    }

    // Disconnect room
    if (_room.connectionState == ConnectionState.connected) {
      _room.disconnect();
    }

    // Stop tracks
    _localVideoTrack?.stop();
    _localAudioTrack?.stop();

    // Dispose room last
    _room.dispose();

    super.dispose();
  }

  void _kickUser(String userId) {
    SocketService.instance.kickAudience(userId);
  }

  void _muteUser(String userId) {
    SocketService.instance.muteAudience(userId);
  }

  void _unmuteUser(String s) {
    SocketService.instance.unMuteAudience(s);
  }

  void _sendComment() {
    final msg = _chatController.text.trim();
    if (msg.isNotEmpty) {
      SocketService.instance.sendComment(msg);
      _chatController.clear();
    }
  }

  void showRequestsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                const Text(
                  "User Requests",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: CachedCircleAvatar(
                          imageUrl: user.profilePic,
                          radius: 16,
                          user: user.settings,
                        ),
                        title: Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            const Icon(
                              Icons.diamond,
                              size: 12,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${user.diamond}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed: () {
                                users.remove(user);
                                SocketService.instance.joinRequestAccepted(
                                  user,
                                );

                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Accepted ${user.name}"),
                                  ),
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
                                  SnackBar(
                                    content: Text("Deleted ${user.name}"),
                                  ),
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
    if (!isStreaming) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                "Preparing live stream...",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    /// Host avatar
                    GestureDetector(
                      onTap: () async {
                        final tappedUserId = session.hosts.first.userId;
                        if (tappedUserId == SocketService.instance.userId)
                          return;

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
                        imageUrl: Variables.currentUser?.profilePic,
                        user: Variables.currentUser?.settings,
                        radius: 20,
                      ),
                    ),



                    /// Name + viewers + list
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
                              const SizedBox(width: 8),
                              _buildConnectionStatus(),
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

                    /// Compact close button
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

              if (_isReconnecting)
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.orange),
                          const SizedBox(height: 10),
                          Text(
                            "Reconnecting... (Attempt $_reconnectAttempts/$_maxReconnectAttempts)",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
                  child: CommentList(
                    comments: comments,
                    isHost: true,
                    onMuteUser: (s) {
                      if (mutedUsers.contains(s)) {
                        mutedUsers.remove(s);
                        _unmuteUser(s);
                      } else {
                        _muteUser(s);
                      }
                    },
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
                        IconButton(
                          onPressed: () {
                            setState(() {
                              // isBeautyEnabled = !isBeautyEnabled;
                            });
                            GenericStreamService.toggleBeauty();
                          },
                          icon: const Icon(Icons.face_retouching_natural),
                        ),
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
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _sendComment();
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
                        onPressed: () {
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
