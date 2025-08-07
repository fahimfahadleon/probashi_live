import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

class CachedNetworkImageBox extends StatefulWidget {
  final String? imageUrl;
  final double height;
  final double width;
  final BoxFit fit;

  const CachedNetworkImageBox({
    super.key,
    required this.imageUrl,
    this.height = 120,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
  });

  @override
  State<CachedNetworkImageBox> createState() => _CachedNetworkImageBoxState();
}

class _CachedNetworkImageBoxState extends State<CachedNetworkImageBox> {
  File? _imageFile;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedNetworkImageBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage(); // Reload image on URL change
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      try {
        final file = await DefaultCacheManager().getSingleFile(widget.imageUrl!);
        if (mounted) {
          setState(() {
            _imageFile = file;
            _loading = false;
          });
        }
      } catch (e) {
        print("Image load error: $e");
        if (mounted) {
          setState(() {
            _error = true;
            _loading = false;
          });
        }
      }
    } else {
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: widget.height,
        width: widget.width,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_error || _imageFile == null) {
      return Container(
        height: widget.height,
        width: widget.width,
        color: Colors.grey,
        alignment: Alignment.center,
        child: const Icon(Icons.person, size: 50, color: Colors.white),
      );
    }

    return Image.file(
      _imageFile!,
      height: widget.height,
      width: widget.width,
      fit: widget.fit,
    );
  }
}
