import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'cached_circle_avatar.dart';

class MiniUserProfileDialog extends StatefulWidget {
  final UserProfile userProfile;
  final Future<UserRelation> Function() onRelationToggle;
  final void Function() onMessage;

  const MiniUserProfileDialog({
    super.key,
    required this.userProfile,
    required this.onRelationToggle,
    required this.onMessage,
  });

  @override
  State<MiniUserProfileDialog> createState() => _MiniUserProfileDialogState();
}

class _MiniUserProfileDialogState extends State<MiniUserProfileDialog> {
  late UserRelation? relation;

  @override
  void initState() {
    super.initState();
    relation = widget.userProfile.relation;
  }

  String _getRelationButtonLabel(UserRelation? relation) {
    if (relation == null) return "Follow";
    if (relation.isFriend) return "Unfriend";
    if (relation.isFollowing) return "Unfollow";
    return "Follow";
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userProfile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.black87,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            CachedCircleAvatar(imageUrl: user.profilePic, radius: 40, user: user.settings,),

            const SizedBox(height: 12),
            Text(
              user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              "ID: ${user.id}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (user.bio != null && user.bio!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  user.bio!,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),

            // Stats and status
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _statusChip("Level ${user.level}", Icons.star),
                const SizedBox(width: 6),
                if (user.vipStatus) _statusChip("VIP", Icons.verified, color: Colors.orange),
                if (user.badge != null) ...[
                  const SizedBox(width: 6),
                  _statusChip(user.badge!, Icons.military_tech, color: Colors.blueAccent),
                ]
              ],
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final updated = await widget.onRelationToggle();
                    setState(() {
                      relation = updated;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    _getRelationButtonLabel(relation),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: widget.onMessage,
                  icon: const Icon(Icons.message, color: Colors.white),
                  label: const Text("Message", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String label, IconData icon, {Color color = Colors.green}) {
    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      avatar: Icon(icon, color: Colors.white, size: 16),
      backgroundColor: color.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
