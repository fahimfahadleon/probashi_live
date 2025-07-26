import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class ParticipantVideoWidget extends StatefulWidget {
  final String streamUrl;

  const ParticipantVideoWidget({super.key, required this.streamUrl});

  @override
  State<ParticipantVideoWidget> createState() => _ParticipantVideoWidgetState();
}

class _ParticipantVideoWidgetState extends State<ParticipantVideoWidget> {
  late VlcPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VlcPlayerController.network(
      widget.streamUrl,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VlcPlayer(
      controller: _controller,
      aspectRatio: 9 / 16,
      placeholder: const Center(child: CircularProgressIndicator()),
    );
  }
}