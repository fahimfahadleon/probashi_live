import 'package:flutter/material.dart';
import 'package:probashi_live/models/user_profile.dart';
import 'package:probashi_live/utils/api_service.dart';
import '../models/chat_history_response.dart';
import '../models/chat_message.dart';
import '../utils/socket_service.dart';
import 'cached_circle_avatar.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  late UserProfile currentUserProfile;
  late UserProfile otherUserProfile;
  bool isProfileLoaded = false;

  bool isLoadingMore = false;
  int page = 1;
  final int limit = 20;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();

    fetchProfile();

    // Register callback for chat history socket event
    SocketService.instance.onChatHistory(_onChatHistoryReceived);

    fetchMessages();

    _scrollController.addListener(() {
      // Load more when near top
      if (_scrollController.offset <= 100 && !isLoadingMore && hasMore) {
        fetchMessages();
      }
    });
    SocketService.instance.onNewMessage((message){
      setState(() {
        messages.add(message);
      });
    });
  }

  @override
  void dispose() {
    // Remove chat history listener on dispose
    SocketService.instance.off('chat_history');
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onChatHistoryReceived(ChatHistoryResponse history) {
    setState(() {
      // Insert new history at start of list (pagination)
      messages.insertAll(0, history.messages);
      hasMore = history.messages.length == limit;
      page++;
      isLoadingMore = false;
    });
  }

  Future<void> fetchProfile() async {
    currentUserProfile = await ApiService.getApiClient().getUserProfile(
      widget.currentUserId,
    );
    otherUserProfile = await ApiService.getApiClient().getUserProfile(
      widget.otherUserId,
    );
    setState(() {
      isProfileLoaded = true;
    });
  }

  Future<void> fetchMessages() async {
    setState(() => isLoadingMore = true);

    SocketService.instance.getChatHistory(
      userId: widget.currentUserId,
      otherUserId: widget.otherUserId,
      page: page,
      limit: limit,
    );
  }

  void sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().toIso8601String(),
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _textController.clear();
    });

    SocketService.instance.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.otherUserId,
      content: text,
    );
  }

  Widget buildMessageBubble(ChatMessage msg) {
    final isMine = msg.senderId == widget.currentUserId;
    final avatar = isMine
        ? currentUserProfile.profilePic
        : otherUserProfile.profilePic;
    final user = isMine ? currentUserProfile : otherUserProfile;

    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMine) ...[
          const SizedBox(width: 8),
          userAvatar(avatar,user),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMine ? Colors.teal.shade300 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100, width: 1),
            ),
            child: Text(
              msg.content,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (isMine) ...[
          const SizedBox(width: 6),
          userAvatar(avatar,user),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.black12)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.teal.shade200),
                ),
              ),
              onSubmitted: (_) => sendMessage(),

            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.teal,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isProfileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else {
      return Scaffold(
        backgroundColor: Colors.teal.shade50,
        appBar: AppBar(
          backgroundColor: Colors.teal,
          title: Row(
            children: [
              userAvatar(otherUserProfile.profilePic,otherUserProfile),
              const SizedBox(width: 10),
              Text(
                otherUserProfile.name,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: messages.isEmpty && !isLoadingMore
                  ? const Center(
                      child: Text(
                        "No chat history available",
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final reversedIndex = messages.length - 1 - index;
                        return buildMessageBubble(messages[reversedIndex]);
                      },
                    ),
            ),
            buildInputArea(),
          ],
        ),
      );
    }
  }

  Widget userAvatar(String? imageUrl, UserProfile userProfile) {
    return CachedCircleAvatar(imageUrl: imageUrl,user: userProfile.settings,);
  }
}
