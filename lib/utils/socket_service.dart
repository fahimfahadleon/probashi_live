import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:probashi_live/utils/variables.dart';

import '../models/live_comment.dart';
import '../models/live_gift.dart';
import '../models/live_session.dart';
import '../models/live_user.dart';

class SocketService {
  // Singleton pattern
  static final SocketService instance = SocketService._internal();

  SocketService._internal();

  // Socket instance and connection state
  late IO.Socket socket;
  bool isConnected = false;

  // User/session identifiers
  String userId = "";
  String? currentSessionId;

  LiveSession? _cachedLiveSession;

  // Socket event names
  static const String GO_LIVE = "go_live";
  static const String LEAVE_LIVE = "leave_live";
  static const String JOIN_SESSION = "join_session";
  static const String JOIN_AUDIENCE = "join_audience";
  static const String USER_ID = "userId";
  static const String RTMP_URL = "rtmpUrl";

  static const String GET_ACTIVE_LIVE_SESSIONS = "get_active_live_sessions";
  static const String ACTIVE_LIVE_SESSIONS = "active_live_sessions";

  // ========================
  // Public API
  // ========================

  /// Initialize and connect socket with JWT token for auth
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

    _registerSocketListeners();
  }

  /// Disconnect socket and clear session data
  void disconnect() {
    socket.disconnect();
    isConnected = false;
    userId = "";
    currentSessionId = null;
    _cachedLiveSession = null;
  }

  /// Start live stream by emitting 'go_live' event with userId and RTMP URL
  void goLive() {
    if (userId.isEmpty) {
      print("Cannot go live: userId is empty");
      return;
    }
    final rtmpUrl = "${Variables.RTMP_URL}/$userId";
    socket.emit(GO_LIVE, {USER_ID: userId, RTMP_URL: rtmpUrl});
  }

  /// Leave the current live session
  void leaveLive() {
    if (userId.isEmpty || currentSessionId == null) {
      print("Cannot leave live: userId or sessionId missing");
      return;
    }
    socket.emit(LEAVE_LIVE, {USER_ID: userId, 'sessionId': currentSessionId});
    currentSessionId = null;
    _cachedLiveSession = null;
  }

  /// Send a comment to the current live session
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

  /// Join a live session as participant
  void joinSession(String sessionId) {
    if (userId.isEmpty) {
      print("Cannot join session: userId is empty");
      return;
    }
    socket.emit(JOIN_SESSION, {'userId': userId, 'sessionId': sessionId});
    currentSessionId = sessionId;
  }

  /// Join a live session as audience
  void joinAudience(String sessionId) {
    if (userId.isEmpty) {
      print("Cannot join audience: userId is empty");
      return;
    }
    socket.emit(JOIN_AUDIENCE, {'userId': userId, 'sessionId': sessionId});
    currentSessionId = sessionId;
  }

  /// Kick participant by userId
  void kickParticipant(String userId) {
    socket.emit('kick_participant', {'userId': userId});
  }

  /// Mute participant by userId
  void muteParticipant(String userId) {
    socket.emit('mute_participant', {'userId': userId});
  }

  /// Request list of active live sessions (endedAt == null)
  void requestActiveLiveSessions() {
    if (!isConnected) {
      print("Socket not connected. Cannot request active live sessions.");
      return;
    }
    socket.emit(GET_ACTIVE_LIVE_SESSIONS);
  }

  // ========================
  // Cached Live Session Getters
  // ========================

  LiveSession? get currentLiveSession => _cachedLiveSession;

  List<LiveUser> getParticipants() => _cachedLiveSession?.participants ?? [];

  List<LiveUser> getHosts() => _cachedLiveSession?.hosts ?? [];

  List<LiveUser> getAudience() => _cachedLiveSession?.audience ?? [];

  List<LiveComment> getComments() => _cachedLiveSession?.comments ?? [];

  List<LiveGift> getGifts() => _cachedLiveSession?.gifts ?? [];

  // ========================
  // Callbacks for various socket events
  // ========================

  void Function(LiveSession liveSession)? _liveStartedCallback;
  void Function(LiveSession liveSession)? _liveEndedCallback;
  void Function(LiveComment comment)? _newCommentCallback;
  void Function(LiveUser participant)? _participantJoinedCallback;
  void Function(LiveUser participant)? _participantLeftCallback;
  void Function(LiveUser audience)? _audienceJoinedCallback;
  void Function(LiveUser audience)? _audienceLeftCallback;
  void Function(LiveGift gift)? _giftReceivedCallback;

  void Function(List<LiveSession> sessions)? _activeLiveSessionsCallback;

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

  /// Callback when active live sessions are received
  void onActiveLiveSessions(void Function(List<LiveSession> sessions) callback) {
    _activeLiveSessionsCallback = callback;
  }

  // ========================
  // Private Helpers
  // ========================

  void _registerSocketListeners() {
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

    socket.on('live_started', (liveSessionJson) {
      final liveSession = LiveSession.fromJson(liveSessionJson);
      print('Live started: ${liveSession.id}');
      cacheLiveSession(liveSession);
      _liveStartedCallback?.call(liveSession);
    });

    socket.on('live_ended', (dataJson) {
      final liveSession = dataJson;
      print('Live ended: ${liveSession.id}');
      if (liveSession.id == currentSessionId) {
        currentSessionId = null;
        _cachedLiveSession = null;
      }
      _liveEndedCallback?.call(liveSession);
    });

    socket.on('new_comment', (commentJson) {
      final comment = commentJson;
      print('New comment: ${comment.message}');
      _newCommentCallback?.call(comment);
    });

    socket.on('participant_joined', (participantJson) {
      final participant = participantJson;
      print('Participant joined: ${participant.user.name}');
      _participantJoinedCallback?.call(participant);
    });

    socket.on('participant_left', (participantJson) {
      final participant = participantJson;
      print('Participant left: ${participant.user.name}');
      _participantLeftCallback?.call(participant);
    });

    socket.on('audience_joined', (audienceJson) {
      final audience = audienceJson;
      print('Audience joined: $audience');
      _audienceJoinedCallback?.call(audience);
    });

    socket.on('audience_left', (audienceJson) {
      final audience = audienceJson;
      _audienceLeftCallback?.call(audience);
    });

    socket.on('gift_received', (giftJson) {
      final gift = giftJson;
      print('Gift received: ${gift.giftType}');
      _giftReceivedCallback?.call(gift);
    });

    socket.on(ACTIVE_LIVE_SESSIONS, (data) {
      print("Received active live sessions: $data");
      try {
        final sessions = (data as List)
            .map((json) => LiveSession.fromJson(json))
            .toList();
        _activeLiveSessionsCallback?.call(sessions);
      } catch (e) {
        print("Error parsing active live sessions: $e");
      }
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

  void cacheLiveSession(LiveSession session) {
    _cachedLiveSession = session;
    currentSessionId = session.id;
  }
}
