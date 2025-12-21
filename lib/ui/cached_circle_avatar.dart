import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:svgaplayer_flutter/player.dart';
import 'package:svgaplayer_flutter/proto/svga.pb.dart';

import '../utils/utils.dart';


class CachedCircleAvatar extends StatefulWidget {
  final String? imageUrl;
  final Map<String, dynamic>? user; // ✅ New parameter
  final double radius;

  const CachedCircleAvatar({
    super.key,
    required this.imageUrl,
    required this.user,
    this.radius = 16,
  });

  @override
  State<CachedCircleAvatar> createState() => _CachedCircleAvatarState();
}

class _CachedCircleAvatarState extends State<CachedCircleAvatar> with SingleTickerProviderStateMixin {
  File? _imageFile;
  late final SVGAAnimationController _svgaController;
  MovieEntity? _videoItem;

  @override
  void initState() {
    super.initState();
    _svgaController = SVGAAnimationController(vsync: this);
    _loadImage();
    _loadActiveFrame();
  }

  @override
  void didUpdateWidget(CachedCircleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  @override
  void dispose() {
    _svgaController.dispose();
    super.dispose();
  }

  void _loadImage() async {
    final imageUrl = widget.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final file = await DefaultCacheManager().getSingleFile(imageUrl);
        if (mounted) {
          setState(() {
            _imageFile = file;
          });
        }
      } catch (e) {
        print("Image load error: $e");
      }
    }
  }

  void _loadActiveFrame() async {
    final settings = widget.user;
    if (settings == null || settings.isEmpty) return;
    final activeFrameId = Utils.getActiveCollectionId(settings, 'frame');

    final data = await Utils.getThumbAndSvgaUrl(activeFrameId);
    final url = data?['imageUrl'];
    if (url == null || !mounted) return;

    try {
      final videoItem = await Utils.getCachedSvga(url);
      if (!mounted || videoItem == null) return;

      _svgaController.videoItem = videoItem;
      _svgaController.repeat();

      setState(() {
        _videoItem = videoItem;
      });
    } catch (e) {
      print("Failed to load SVGA frame:");
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
      child: _imageFile == null
          ? const Icon(Icons.person, size: 16, color: Colors.white)
          : null,
    );

    return SizedBox(
      width: widget.radius * 4.1,
      height: widget.radius * 4.1,
      child: Stack(
        alignment: Alignment.center,
        children: [
          avatar,
          if (_videoItem != null)
            Positioned.fill(
              child: SVGAImage(
                _svgaController,
                fit: BoxFit.scaleDown,
                allowDrawingOverflow: false,
              ),
            ),
        ],
      ),
    );
  }
}
