


import 'package:probashi_live/models/join_request_accepted.dart';
import 'package:probashi_live/models/live_started_event.dart';
import 'package:probashi_live/models/user_profile.dart';
import 'package:probashi_live/models/webrtc_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:probashi_live/utils/variables.dart';

import '../models/chat_history_response.dart';
import '../models/chat_inbox_entry.dart';
import '../models/chat_message.dart';
import '../models/friend_user_model.dart';
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
    socket = IO.io(Variables.BASE_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': jwtToken},
    });

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

  void participantLive(String sessionId){
    final data = {
      'userId': userId,
      'sessionId': sessionId,
      'rtmpUrl': '${Variables.RTMP_URL}/$userId',
    };
    socket.emit('participant_go_live', data);
  }

  /// Leave the current live session
  void leaveLive() {
    socket.emit(LEAVE_LIVE, {USER_ID: userId, 'sessionId': currentSessionId});
    currentSessionId = null;
    _cachedLiveSession = null;
  }

  /// Send a comment to the current live session
  void sendComment(String message) {
    if (userId.isEmpty || currentSessionId == null) {
      print('userId: $userId, sessionId: $currentSessionId');
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
  void kickAudience(String userId) {
    socket.emit('kick_audience', {'userId': userId, 'sessionId': currentSessionId});
  }

  /// Mute participant by userId
  void muteAudience(String userId) {
    socket.emit('mute_audience', {'userId': userId, 'sessionId': currentSessionId});
  }  /// Mute participant by userId
  void unMuteAudience(String userId) {
    socket.emit('unmute_audience', {'userId': userId, 'sessionId': currentSessionId});
  }

  /// Request list of active live sessions (endedAt == null)
  void requestActiveLiveSessions() {
    if (!isConnected) {
      print("Socket not connected. Cannot request active live sessions.");
      return;
    }
    socket.emit(GET_ACTIVE_LIVE_SESSIONS);
  }
  void requestLiveSessionDetails(String sessionId){
    socket.emit("get_live_session_details", {'sessionId': sessionId});
  }

  void sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) {
    socket.emit('send_message', {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
    });
  }

  void getChatHistory({
    required String userId,
    required String otherUserId,
    int page = 1,
    int limit = 20,
  }) {
    socket.emit('get_chat_history', {
      'userId': userId,
      'otherUserId': otherUserId,
      'page': page,
      'limit': limit,
    });
  }

  void audienceLeave(){
    if (!isConnected || currentSessionId == null || userId.isEmpty) {
      print("Something went wrong.");
      return;
    }
    socket.emit('leave_audience', {
      'userId': userId,
     'sessionId': currentSessionId,
    });
  }

  void sendGift(LiveGift gift) {
    if (!isConnected || currentSessionId == null || userId.isEmpty) {
      print("Cannot send gift: Missing session or user info");
      return;
    }
    socket.emit('send_gift', gift.toJson());
  }

  void getChatInbox() {
    socket.emit('get_chat_inbox', {'userId': userId});
  }

  void off(String eventName) {
    socket.off(eventName);
  }

  void inviteToJoinLive({
    required String fromUserId,
    required String toUserId,
    required String sessionId,
  }) {
    socket.emit('invite_to_join_live', {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'sessionId': sessionId,
    });
  }

  void acceptInvite({required String fromUserId, required String userId, required String sessionId}) {
    socket.emit('invite_accepted', {'fromUserId':fromUserId,'userId': userId, 'sessionId': sessionId});
  }

  void cancelInvite({
    required String fromUserId,
    required String toUserId,
    required String sessionId,
  }) {
    socket.emit('invite_canceled', {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'sessionId': sessionId,
    });
  }

  void onChatInbox(void Function(List<ChatInboxEntry>) callback) {
    socket.on('chat_inbox', (data) {
      final List<ChatInboxEntry> inbox = (data as List)
          .map((entry) => ChatInboxEntry.fromJson(entry))
          .toList();
      callback(inbox); // ✅ Call the callback with typed list
    });
  }

  void getFriends() {
    socket.emit('get_friends');
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

  void Function(LiveStartedEvent liveSession)? _liveStartedCallback;
  void Function(LiveSession liveSession)? _liveEndedCallback;
  void Function(LiveSession liveSession)? _sessionUpdatedCallback;
  void Function(LiveComment comment)? _newCommentCallback;
  void Function(LiveUser participant)? _participantJoinedCallback;
  void Function(LiveUser participant)? _participantLeftCallback;
  void Function(Map<String, dynamic> audience)? _audienceJoinedCallback;
  void Function(UserProfile userProfile)? _audienceRequestedCallback;
  void Function(Map<String, dynamic> audience)? _audienceLeftCallback;
  void Function(Map<String, dynamic> audience)? _giftReceivedCallback;
  void Function(ChatMessage message)? _newMessageCallback;
  void Function(ChatHistoryResponse response)? _chatHistoryCallback;

  void Function(List<LiveSession> sessions)? _activeLiveSessionsCallback;
  void Function(Map<String, dynamic> inviteData)? _liveInviteCallback;

  void Function(Map<String, dynamic>)? _inviteAcceptedCallback;
  void Function(Map<String, dynamic>)? _inviteCanceledCallback;
  void Function(List<FriendUserModel>)? _friendsListCallback;
  void Function(LiveSession)? _participantLiveStartedCallback;
  void Function(LiveSession)? _getLiveDetails;
  void Function(JoinRequestAccepted)? _onInvitationAccepted;
  void Function(Map<String, dynamic>)?_onKickAudience;
  void Function(Map<String, dynamic>)?_onMuteAudience;
  void Function(Map<String, dynamic>)?_onUnMuteAudience;
  void Function(WebRTCResponse)?_onWebRtcData;

  void onWebRTCResponse(void Function(WebRTCResponse rtcResponse) param0){
    _onWebRtcData = param0;
  }


  void onAudienceUnMute(void Function(Map<String, dynamic>) param0) {
    _onUnMuteAudience = param0;
  }

  void onAudienceKicked(void Function(Map<String, dynamic>) callback) {
    _onKickAudience = callback;
  }
  void onAudienceMuted(void Function(Map<String, dynamic>) callback) {
    _onMuteAudience = callback;
  }
  void onLiveDetailData(void Function(LiveSession) callback) {
    _getLiveDetails = callback;
  }
  void onInvitationAcceptedCallback(void Function(JoinRequestAccepted)callback){
    _onInvitationAccepted = callback;
  }

  void onParticipantLiveStarted(void Function(LiveSession) callback) {
    _participantLiveStartedCallback = callback;
  }

  void onFriendListCalled(void Function(List<FriendUserModel>) callback) {
    _friendsListCallback = callback;
  }



  void onInviteAccepted(void Function(Map<String, dynamic>) callback) {
    _inviteAcceptedCallback = callback;
  }

  void onInviteCanceled(void Function(Map<String, dynamic>) callback) {
    _inviteCanceledCallback = callback;
  }

  void onLiveInvite(void Function(Map<String, dynamic> inviteData) callback) {
    _liveInviteCallback = callback;
  }

  void onLiveStarted(void Function(LiveStartedEvent liveSession) callback) {
    _liveStartedCallback = callback;
  }

  void onLiveEnded(void Function(LiveSession liveSession) callback) {
    _liveEndedCallback = callback;
  }

  void onSessionUpdated(void Function(LiveSession liveSession) callback) {
    _sessionUpdatedCallback = callback;
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

  void onAudienceJoined(void Function(Map<String, dynamic> audience) callback) {
    _audienceJoinedCallback = callback;
  }
  void onAudienceRequested(void Function(UserProfile profile) callback) {
    _audienceRequestedCallback = callback;
  }

  void onAudienceLeft(void Function(Map<String, dynamic> audience) callback) {
    _audienceLeftCallback = callback;
  }

  void onGiftReceived(void Function(Map<String, dynamic> audience) callback) {
    _giftReceivedCallback = callback;
  }

  /// Callback when active live sessions are received
  void onActiveLiveSessions(
    void Function(List<LiveSession> sessions) callback,
  ) {
    _activeLiveSessionsCallback = callback;
  }

  void onNewMessage(void Function(ChatMessage message) callback) {
    _newMessageCallback = callback;
  }

  void onChatHistory(void Function(ChatHistoryResponse response) callback) {
    _chatHistoryCallback = callback;
  }




  // ========================
  // Private Helpers
  // ========================

  void _registerSocketListeners() {
    socket.on('connect', (_) {
      print('Connected to socket with id: ${socket.id}');
      isConnected = true;
    });
    
    
    socket.on("live_session_details", (data){
      LiveSession liveSession = LiveSession.fromJson(data);
      currentSessionId = liveSession.id;
      _getLiveDetails?.call(liveSession);
    });

    socket.on('connected', (data) {
      print('Server says: ${data['message']}');
      if (data['userId'] != null) {
        userId = data['userId'];
      }
    });

    socket.on('kicked_from_session', (data){
      _onKickAudience?.call(data);
    });

    socket.on('unmuted_audience', (data){
      _onUnMuteAudience?.call(data);
    });

    socket.on('muted_from_session', (data){
      _onMuteAudience?.call(data);
    });

    socket.on('participant_live_started', (data){
      LiveSession liveSession = LiveSession.fromJson(data);
      currentSessionId = liveSession.id;
      _participantLiveStartedCallback?.call(liveSession);
    });

    socket.on('friends_list', (data) {
      List<FriendUserModel> friendList = (data as List)
          .map((json) => FriendUserModel.fromJson(json))
          .toList();
      _friendsListCallback?.call(friendList);
    });
    socket.on('invite_accepted', (data) {
      print('Invite accepted: $data');
      _inviteAcceptedCallback?.call(data);
    });

    socket.on('invite_canceled', (data) {
      print('Invite canceled: $data');
      _inviteCanceledCallback?.call(data);
    });

    socket.on('live_invite', (data) {
      _liveInviteCallback?.call(data); // Call the registered Flutter callback
    });

    socket.on('live_started', (liveSessionJson) {
      print(liveSessionJson);
      final liveSession = LiveStartedEvent.fromJson(liveSessionJson);
      print('Live started: ${liveSession.fullSession.id}');
      cacheLiveSession(liveSession.fullSession);
      _liveStartedCallback?.call(liveSession);
    });

    socket.on('live_ended', (dataJson) {
      final liveSession = LiveSession.fromJson(dataJson);
      if (liveSession.id == currentSessionId) {
        currentSessionId = null;
        _cachedLiveSession = null;
      }
      _liveEndedCallback?.call(liveSession);
    });

    socket.on('session_updated', (dataJson) {
      final updatedSession = LiveSession.fromJson(dataJson);
      cacheLiveSession(updatedSession); // ⬅️ Keep cache in sync
      _sessionUpdatedCallback?.call(updatedSession);
    });

    socket.on('new_comment', (commentJson) {
      final comment = LiveComment.fromJson(commentJson);
      _newCommentCallback?.call(comment);
    });

    socket.on('participant_joined', (participantJson) {
      print("participant joined: $participantJson");
      final participant = LiveUser.fromJson(participantJson);
      _participantJoinedCallback?.call(participant);
    });

    socket.on('participant_left', (participantJson) {

      print("participant left: $participantJson");

      final participant = LiveUser.fromJson(participantJson['liveUser']);
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
      print("gift received: $giftJson");
      _giftReceivedCallback?.call(giftJson);
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
    socket.on('audience_request_received', (data){
      UserProfile profile = UserProfile.fromJson(data);
      _audienceRequestedCallback?.call(profile);
    });

    socket.on('disconnect', (_) {
      print('Socket disconnected');
      isConnected = false;
    });

    socket.on('join_request_accepted', (payload){
      print('join request accepted data: $payload');
      _onInvitationAccepted?.call(JoinRequestAccepted.fromJson(payload));
    });

    socket.on('connect_error', (error) {
      print('Connection error: $error');
      isConnected = false;
    });

    socket.on('error', (data) {
      final code = data['code'];
      final message = data['message'];

      print("error: "+message);
      // Show specific UI or messages based on code
    });

    socket.on('new_message', (data) {
      final message = ChatMessage.fromJson(data);
      _newMessageCallback?.call(message);
    });

    socket.on('chat_history', (data) {
      final history = ChatHistoryResponse.fromJson(data);
      _chatHistoryCallback?.call(history);
    });
    socket.on('webrtc_token', (data) {
      _onWebRtcData?.call(WebRTCResponse.fromJson(data));
    });

  }

  void cacheLiveSession(LiveSession session) {
    _cachedLiveSession = session;
    currentSessionId = session.id;
  }

  void participantLeft() {
    if (userId.isEmpty || currentSessionId == null) {
      print("Cannot leave live: userId or sessionId missing");
      return;
    }
    socket.emit('participant_left', {USER_ID: userId, 'sessionId': currentSessionId});
  }

  void requestToJoin(String senderId,String receiverId) {
    if (userId.isEmpty || currentSessionId == null) {
      return;
    }
    socket.emit('join_request', {USER_ID: senderId, 'sessionId': currentSessionId, 'senderId': senderId, 'receiverId': receiverId});
  }

  void joinRequestAccepted(UserProfile user) {
    if (userId.isEmpty || currentSessionId == null) {
      return;
    }
    socket.emit('join_request_accepted',{'userId': user.id, 'sessionId': currentSessionId, 'fromUser': userId});
  }


}
