import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Simplified Dart models for demo
class LiveUser {
  final String id;
  final String name;
  final bool isHost;
  final String profilePicUrl;

  LiveUser({
    required this.id,
    required this.name,
    this.isHost = false,
    this.profilePicUrl = '',
  });

  factory LiveUser.fromJson(Map<String, dynamic> json) => LiveUser(
    id: json['id'],
    name: json['name'],
    isHost: json['isHost'] ?? false,
    profilePicUrl: json['profilePicUrl'] ?? '',
  );
}

class LiveComment {
  final String id;
  final LiveUser user;
  final String message;
  final DateTime createdAt;

  LiveComment({
    required this.id,
    required this.user,
    required this.message,
    required this.createdAt,
  });

  factory LiveComment.fromJson(Map<String, dynamic> json) => LiveComment(
    id: json['id'],
    user: LiveUser.fromJson(json['user']),
    message: json['message'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class LiveSession {
  final String id;
  final List<LiveUser> hosts;
  final List<LiveUser> participants;
  final List<LiveComment> comments;

  LiveSession({
    required this.id,
    this.hosts = const [],
    this.participants = const [],
    this.comments = const [],
  });

  LiveSession copyWith({
    List<LiveUser>? hosts,
    List<LiveUser>? participants,
    List<LiveComment>? comments,
  }) {
    return LiveSession(
      id: id,
      hosts: hosts ?? this.hosts,
      participants: participants ?? this.participants,
      comments: comments ?? this.comments,
    );
  }
}

class LiveView extends StatefulWidget {
  final String sessionId;
  final String socketUrl; // e.g. https://your-backend.com

  const LiveView({
    super.key,
    required this.sessionId,
    required this.socketUrl,
  });

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  late IO.Socket socket;
  late LiveSession session;

  @override
  void initState() {
    super.initState();

    session = LiveSession(id: widget.sessionId);

    socket = IO.io(widget.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('Socket connected');
      socket.emit('join_session', {'sessionId': widget.sessionId});
    });

    socket.on('hosts_update', (data) {
      final hosts = (data as List).map((e) => LiveUser.fromJson(e)).toList();
      setState(() {
        session = session.copyWith(hosts: hosts);
      });
    });

    socket.on('participants_update', (data) {
      final participants = (data as List).map((e) => LiveUser.fromJson(e)).toList();
      setState(() {
        session = session.copyWith(participants: participants);
      });
    });

    socket.on('new_comment', (data) {
      final comment = LiveComment.fromJson(data);
      setState(() {
        session = session.copyWith(comments: [comment, ...session.comments]);
      });
    });

    socket.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    super.dispose();
  }

  Widget _buildUserPreview(LiveUser user, {double size = 100}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: user.isHost ? Colors.amber : Colors.white),
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: user.profilePicUrl.isNotEmpty
              ? NetworkImage(user.profilePicUrl)
              : const AssetImage('assets/default_avatar.png') as ImageProvider,
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            user.name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildHostsRow() {
    final hosts = session.hosts;
    if (hosts.isEmpty) {
      return const SizedBox.shrink();
    }
    if (hosts.length == 1) {
      return Center(
        child: _buildUserPreview(hosts[0], size: 300),
      );
    }
    // two hosts side by side
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: hosts
          .map((host) => _buildUserPreview(host, size: 150))
          .toList(),
    );
  }

  Widget _buildParticipantsGrid() {
    final participants = session.participants;
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }
    // Grid of participants with 4 per row
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: participants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1 / 1.5,
      ),
      itemBuilder: (context, index) {
        return _buildUserPreview(participants[index], size: 100);
      },
    );
  }

  Widget _buildCommentsList() {
    final comments = session.comments;
    return ListView.separated(
      shrinkWrap: true,
      reverse: true,
      itemCount: comments.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.grey),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: comment.user.profilePicUrl.isNotEmpty
                ? NetworkImage(comment.user.profilePicUrl)
                : const AssetImage('assets/default_avatar.png') as ImageProvider,
          ),
          title: Text(comment.user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(comment.message),
          trailing: Text(
            _formatTime(comment.createdAt),
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Live Session: ${session.id}'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Hosts preview row
          SizedBox(
            height: 320,
            child: _buildHostsRow(),
          ),

          // Participants grid
          Expanded(
            child: _buildParticipantsGrid(),
          ),

          // Comments section
          Container(
            height: 200,
            color: Colors.black87,
            child: _buildCommentsList(),
          ),

          // Input & action row placeholder
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: TextStyle(color: Colors.white60),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (text) {
                      // TODO: send comment to socket
                      if (text.trim().isNotEmpty) {
                        socket.emit('send_comment', {'sessionId': session.id, 'message': text});
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: () {
                    // TODO: implement sending comment on button press
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
