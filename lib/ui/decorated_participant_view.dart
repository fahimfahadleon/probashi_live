import 'dart:async';
import 'package:flutter/material.dart';
import 'package:probashi_live/models/live_user.dart';
import 'package:probashi_live/models/user_profile.dart';
import 'package:probashi_live/ui/cached_circle_avatar.dart';
import 'participant_video_widget.dart'; // adjust the import path as needed

class DecoratedParticipantView extends StatefulWidget {
  final String streamUrl;
  final String avatarUrl;
  final VoidCallback onProfileTap;
  final VoidCallback onGiftTap;
  final String overlayText;
  final UserProfile liveUser;

  const DecoratedParticipantView({
    super.key,
    required this.streamUrl,
    required this.avatarUrl,
    required this.onProfileTap,
    required this.onGiftTap,
    required this.overlayText,
    required this.liveUser,
  });

  @override
  State<DecoratedParticipantView> createState() => _DecoratedParticipantViewState();
}

class _DecoratedParticipantViewState extends State<DecoratedParticipantView> {
  bool _showTextField = false;
  Timer? _hideTimer;

  void _handleAvatarTap() {
    if (_showTextField) {
      _hideTimer?.cancel();
      widget.onProfileTap(); // second tap = open profile
    } else {
      setState(() => _showTextField = true);
      _hideTimer = Timer(const Duration(seconds: 2), () {
        setState(() => _showTextField = false);
      });
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Stack(
          children: [
            // VLC video player
            Positioned.fill(
              child: ParticipantVideoWidget(streamUrl: widget.streamUrl),
            ),

            // Avatar in top-left
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: _handleAvatarTap,
                child: CachedCircleAvatar(imageUrl: widget.avatarUrl,radius: 15, user: widget.liveUser.settings),
              ),
            ),

            // Temporary text field
            if (_showTextField)
              Positioned(
                top: 8,
                left: 52,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: (0.6 * 255).toDouble()),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.overlayText,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

            // Gift icon at bottom-right
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: widget.onGiftTap,
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}