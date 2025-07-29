import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

class CachedCircleAvatar extends StatefulWidget {
  final String? imageUrl;
  final double radius;

  const CachedCircleAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 16,
  });

  @override
  State<CachedCircleAvatar> createState() => _CachedCircleAvatarState();
}

class _CachedCircleAvatarState extends State<CachedCircleAvatar> {
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedCircleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage(); // Re-fetch if the imageUrl changes
    }
  }

  void _loadImage() async {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      try {
        final file =
        await DefaultCacheManager().getSingleFile(widget.imageUrl!);
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

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.grey.shade300,
      backgroundImage:
      _imageFile != null ? FileImage(_imageFile!) : null,
      child: _imageFile == null
          ? const Icon(Icons.person, size: 16, color: Colors.white)
          : null,
    );
  }
}
