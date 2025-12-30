import 'package:flutter/material.dart';
import 'package:flutter_svga/flutter_svga.dart';
import 'package:probashi_live/models/user_profile.dart';
import 'package:probashi_live/ui/cached_circle_avatar.dart';
import 'package:probashi_live/utils/variables.dart';


import '../utils/utils.dart';

class SVGAOverlay extends StatefulWidget {
  final UserProfile userSettings;
  final String collectionType;
  final double width;
  final double height;

  const SVGAOverlay({
    super.key,
    required this.userSettings,
    required this.collectionType,
    required this.width,
    required this.height,
  });

  @override
  State<SVGAOverlay> createState() => _SVGAOverlayState();
}

class _SVGAOverlayState extends State<SVGAOverlay> with SingleTickerProviderStateMixin {
  late final SVGAAnimationController _controller;
  MovieEntity? _videoItem;
  int _currentLoadId = 0; // to track latest load request

  @override
  void initState() {
    super.initState();
    _controller = SVGAAnimationController(vsync: this);
    _loadSVGA();
  }

  @override
  void didUpdateWidget(covariant SVGAOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userSettings != widget.userSettings ||
        oldWidget.collectionType != widget.collectionType) {
      _loadSVGA();
    }
  }

  void _loadSVGA() async {
    final loadId = ++_currentLoadId; // increment to track latest load
    final settings = widget.userSettings.settings;
    if (settings == null || settings.isEmpty) {
      if (mounted) {
        setState(() {
          _videoItem = null;
        });
      }
      return;
    }

    final id = Utils.getActiveCollectionId(settings, widget.collectionType);
    final data = await Utils.getThumbAndSvgaUrl(id);
    final url = data?['imageUrl'];
    if (url == null || !mounted) {
      if (mounted) {
        setState(() {
          _videoItem = null;
        });
      }
      return;
    }

    try {
      final videoItem = await Utils.getCachedSvga("${Variables.BASE_URL}/$url");
      if (!mounted || videoItem == null) return;

      // Check if this is still the latest load
      if (loadId != _currentLoadId) return;

      _controller.videoItem = videoItem;
      _controller.repeat();

      setState(() {
        _videoItem = videoItem;
      });
    } catch (e) {
      print("SVGA load failed: $e");
      if (mounted) {
        setState(() {
          _videoItem = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoItem == null) return const SizedBox.shrink();

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          // Background SVGA animation
          SVGAImage(
            _controller,
            fit: BoxFit.contain,
            allowDrawingOverflow: false,
          ),

          // Avatar on the left, vertically centered
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: CachedCircleAvatar(
                  imageUrl: widget.userSettings.profilePic,
                  user: {},
                  radius: 10,
                ),
              ),
            ),
          ),

          // Name centered both horizontally and vertically
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "${widget.userSettings.name} Joined.",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

  }

}
