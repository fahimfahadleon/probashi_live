import 'package:flutter/material.dart';
import 'package:probashi_live/models/chat_inbox_entry.dart';
import '../utils/socket_service.dart';
import 'cached_circle_avatar.dart';
import 'one_to_one_chat.dart';
import 'package:intl/intl.dart';

class ChatInboxPage extends StatefulWidget {
  const ChatInboxPage({super.key});

  @override
  State<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends State<ChatInboxPage> {
  List<ChatInboxEntry> inbox = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  @override
  void dispose() {
    SocketService.instance.off("chat_inbox"); // remove listener if needed
    super.dispose();
  }

  void _loadInbox() {
    setState(() => isLoading = true);

    // Request the inbox data
    SocketService.instance.getChatInbox();

    // Register the listener
    SocketService.instance.onChatInbox((inboxList) {
      if (mounted) {
        setState(() {
          inbox = inboxList;
          isLoading = false;
        });
      }
    });

    // Fallback in case socket doesn't return anything
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.Hm().format(time); // today -> HH:mm
    } else {
      return DateFormat('dd MMM').format(time); // e.g., 18 Jul
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats',style: TextStyle(color: Colors.white),),
        backgroundColor: Colors.purple.shade900.withOpacity(0.9),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : inbox.isEmpty
          ? const Center(child: Text("No conversations yet."))
          : ListView.builder(
        itemCount: inbox.length,
        itemBuilder: (context, index) {
          final item = inbox[index];

          print("message item: ${item.user.toJson()}");

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(currentUserId: SocketService.instance.userId, otherUserId: item.user.id),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                gradient: LinearGradient(
                  colors: [Color(0xFFDCB3FF), Color(0xFFB3E5FC)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  CachedCircleAvatar(imageUrl: item.user.profilePic, radius: 25,user: item.user.settings,),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.latestMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
