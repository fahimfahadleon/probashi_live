import 'package:flutter/material.dart';
import 'package:probashi_live/ui/svga_overlay.dart';

import '../models/live_comment.dart';
import '../models/user_profile.dart';
import '../utils/api_service.dart';
import '../utils/socket_service.dart';
import '../utils/utils.dart';
import 'cached_circle_avatar.dart';

class CommentList extends StatelessWidget {
  final List<LiveComment> comments;
  final bool isHost;
  final void Function(String userId)? onMuteUser;
  final void Function(String userId)? onKickUser;

  const CommentList({
    super.key,
    required this.comments,
    this.isHost = false,
    this.onMuteUser,
    this.onKickUser,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      reverse: true,
      itemCount: comments.length,
      itemBuilder: (context, index) {
        final c = comments[comments.length - 1 - index]; // simpler
        final user = c.liveUser.user;

        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
              children: [
                GestureDetector(
                  onTap: () async {
                    final myId = SocketService.instance.userId;
                    if (user.id == myId) return;

                    final client = ApiService.getApiClient();
                    final stats = await client.getUserStats(user.id);
                    user.stats = stats;

                    final profile = await client.getUserProfile(user.id);
                    profile.stats = stats;

                    Utils.showMiniProfileDialog(userProfile: profile, context: context);
                  },
                  child: CachedCircleAvatar(
                    imageUrl: user.profilePic,
                    user: {}, // no SVGA
                    radius: 15,
                  ),
                ),
                const SizedBox(width: 2), // Reduced gap
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // to avoid extra height
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2), // Reduced vertical gap
                        Text(
                          c.message,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
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

      },
    );
  }
}
