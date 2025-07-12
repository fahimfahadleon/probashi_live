import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:probashi_live/utils/variables.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();

  String userId = "";
  String? currentSessionId;

  static const String GO_LIVE = "go_live";
  static const String LEAVE_LIVE = "leave_live";
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
        'auth': {
          'token': jwtToken,
        },
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

    socket.on('live_started', (liveSession) {
      print('Live started: $liveSession');
      currentSessionId = liveSession['id']; // store current live session ID
      _liveStartedCallback?.call(liveSession);
    });

    socket.on('live_ended', (data) {
      print('Live ended: $data');
      if (data['sessionId'] == currentSessionId) {
        currentSessionId = null;
      }
      _liveEndedCallback?.call(data);
    });

    socket.on('new_comment', (comment) {
      print('New comment: $comment');
      _newCommentCallback?.call(comment);
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
    if (userId.isEmpty) {
      print("Cannot leave live: userId is empty");
      return;
    }
    socket.emit(LEAVE_LIVE, {USER_ID: userId});
    currentSessionId = null;
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

  // Callbacks for events
  void Function(dynamic liveSession)? _liveStartedCallback;
  void Function(dynamic data)? _liveEndedCallback;
  void Function(dynamic comment)? _newCommentCallback;

  void onLiveStarted(void Function(dynamic liveSession) callback) {
    _liveStartedCallback = callback;
  }

  void onLiveEnded(void Function(dynamic data) callback) {
    _liveEndedCallback = callback;
  }

  void onNewComment(void Function(dynamic comment) callback) {
    _newCommentCallback = callback;
  }
}
