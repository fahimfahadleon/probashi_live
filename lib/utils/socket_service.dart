import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:probashi_live/utils/variables.dart';

import '../models/live_comment.dart';
import '../models/live_gift.dart';
import '../models/live_session.dart';
import '../models/live_user.dart';


class SocketService {
  static final SocketService instance = SocketService._internal();

  String userId = "";
  String? currentSessionId;

  static const String GO_LIVE = "go_live";
  static const String LEAVE_LIVE = "leave_live";
  static const String JOIN_SESSION = "join_session";
  static const String JOIN_AUDIENCE = "join_audience";
  static const String USER_ID = "userId";
  static const String RTMP_URL = "rtmpUrl";

  late IO.Socket socket;
  bool isConnected = false;

  SocketService._internal();

  void connect(String jwtToken) {
    socket = IO.io(
      Variables.BASE_URL,
      <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': jwtToken},
      },
    );

    socket.connect();

    socket.on('connect', (_) {
      print('Connected to socket with id: ${socket.id}');
      isConnected = true;
    });

    socket.on('connected', (data) {
      print('Server says: ${data['message']}');
      if (data['userId'] != null) {
        userId = data['userId'];
      }
    });

    // Deserialize liveSession from JSON into model
    socket.on('live_started', (liveSessionJson) {
      print(liveSessionJson);
      final liveSession = LiveSession.fromJson(liveSessionJson);
      print('Live started: ${liveSession.id}');
      cacheLiveSession(liveSession);
      _liveStartedCallback?.call(liveSession);
    });

    socket.on('live_ended', (dataJson) {
      final liveSession = LiveSession.fromJson(dataJson);
      print('Live ended: ${liveSession.id}');
      if (liveSession.id == currentSessionId) {
        currentSessionId = null;
        _cachedLiveSession = null;
      }
      _liveEndedCallback?.call(liveSession);
    });

    socket.on('new_comment', (commentJson) {
      final comment = LiveComment.fromJson(commentJson);
      print('New comment: ${comment.message}');
      _newCommentCallback?.call(comment);
    });

    socket.on('participant_joined', (participantJson) {
      final participant = LiveUser.fromJson(participantJson);
      print('Participant joined: ${participant.user.name}');
      _participantJoinedCallback?.call(participant);
    });

    socket.on('participant_left', (participantJson) {
      final participant = LiveUser.fromJson(participantJson);
      print('Participant left: ${participant.user.name}');
      _participantLeftCallback?.call(participant);
    });

    socket.on('audience_joined', (audienceJson) {
      final audience = LiveUser.fromJson(audienceJson);
      print('Audience joined: ${audience.user.name}');
      _audienceJoinedCallback?.call(audience);
    });

    socket.on('audience_left', (audienceJson) {
      final audience = LiveUser.fromJson(audienceJson);
      print('Audience left: ${audience.user.name}');
      _audienceLeftCallback?.call(audience);
    });

    socket.on('gift_received', (giftJson) {
      final gift = LiveGift.fromJson(giftJson);
      print('Gift received: ${gift.giftType}');
      _giftReceivedCallback?.call(gift);
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
      isConnected = false;
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
      isConnected = false;
    });
  }

  void disconnect() {
    socket.disconnect();
    isConnected = false;
    userId = "";
    currentSessionId = null;
    _cachedLiveSession = null;
  }

  void goLive() {
    if (userId.isEmpty) {
      print("Cannot go live: userId is empty");
      return;
    }
    final rtmpUrl = "${Variables.RTMP_URL}/$userId";
    socket.emit(GO_LIVE, {USER_ID: userId, RTMP_URL: rtmpUrl});
  }

  void leaveLive() {
    if (userId.isEmpty || currentSessionId == null) {
      print("Cannot leave live: userId or sessionId missing");
      return;
    }
    socket.emit(LEAVE_LIVE, {USER_ID: userId, 'sessionId': currentSessionId});
    currentSessionId = null;
    _cachedLiveSession = null;
  }

  void sendComment(String message) {
    if (userId.isEmpty || currentSessionId == null) {
      print("Cannot send comment: userId or sessionId missing");
      return;
    }
    socket.emit('send_comment', {
      'message': message,
      'sessionId': currentSessionId,
      'userId': userId,
    });
  }

  void joinSession(String sessionId) {
    if (userId.isEmpty) {
      print("Cannot join session: userId is empty");
      return;
    }
    socket.emit(JOIN_SESSION, {'userId': userId, 'sessionId': sessionId});
    currentSessionId = sessionId;
  }

  void joinAudience(String sessionId) {
    if (userId.isEmpty) {
      print("Cannot join audience: userId is empty");
      return;
    }
    socket.emit(JOIN_AUDIENCE, {'userId': userId, 'sessionId': sessionId});
    currentSessionId = sessionId;
  }

  LiveSession? _cachedLiveSession;

  void cacheLiveSession(LiveSession session) {
    _cachedLiveSession = session;
    currentSessionId = session.id;
  }

  LiveSession? get currentLiveSession => _cachedLiveSession;

  List<LiveUser> getParticipants() {
    return _cachedLiveSession?.participants ?? [];
  }

  List<LiveUser> getHosts() {
    return _cachedLiveSession?.hosts ?? [];
  }

  List<LiveUser> getAudience() {
    return _cachedLiveSession?.audience ?? [];
  }

  List<LiveComment> getComments() {
    return _cachedLiveSession?.comments ?? [];
  }

  List<LiveGift> getGifts() {
    return _cachedLiveSession?.gifts ?? [];
  }

  // Callbacks
  void Function(LiveSession liveSession)? _liveStartedCallback;
  void Function(LiveSession liveSession)? _liveEndedCallback;
  void Function(LiveComment comment)? _newCommentCallback;
  void Function(LiveUser participant)? _participantJoinedCallback;
  void Function(LiveUser participant)? _participantLeftCallback;
  void Function(LiveUser audience)? _audienceJoinedCallback;
  void Function(LiveUser audience)? _audienceLeftCallback;
  void Function(LiveGift gift)? _giftReceivedCallback;

  void onLiveStarted(void Function(LiveSession liveSession) callback) {
    _liveStartedCallback = callback;
  }

  void onLiveEnded(void Function(LiveSession liveSession) callback) {
    _liveEndedCallback = callback;
  }

  void onNewComment(void Function(LiveComment comment) callback) {
    _newCommentCallback = callback;
  }

  void onParticipantJoined(void Function(LiveUser participant) callback) {
    _participantJoinedCallback = callback;
  }

  void onParticipantLeft(void Function(LiveUser participant) callback) {
    _participantLeftCallback = callback;
  }

  void onAudienceJoined(void Function(LiveUser audience) callback) {
    _audienceJoinedCallback = callback;
  }

  void onAudienceLeft(void Function(LiveUser audience) callback) {
    _audienceLeftCallback = callback;
  }

  void onGiftReceived(void Function(LiveGift gift) callback) {
    _giftReceivedCallback = callback;
  }

  void kickParticipant(String userId) {
    socket.emit('kick_participant', {'userId': userId});
  }

  void muteParticipant(String userId) {
    socket.emit('mute_participant', {'userId': userId});
  }
}
