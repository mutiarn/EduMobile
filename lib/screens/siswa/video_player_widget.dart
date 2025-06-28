import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeVideoPlayerPage extends StatefulWidget {
  final String videoId;
  final String title;

  const YoutubeVideoPlayerPage({
    super.key,
    required this.videoId,
    required this.title,
  });

  @override
  State<YoutubeVideoPlayerPage> createState() => _YoutubeVideoPlayerPageState();
}

class _YoutubeVideoPlayerPageState extends State<YoutubeVideoPlayerPage> {
  late YoutubePlayerController _controller;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Auto fullscreen saat pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _enterFullScreen();
    });
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    setState(() {
      _isFullScreen = true;
    });
  }

  void _exitToMiniplayer() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Pop halaman ini dan tampilkan miniplayer overlay
    Navigator.of(context).pop();

    // Tampilkan miniplayer sebagai overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return MiniPlayerOverlay(
          controller: _controller,
          title: widget.title,
          onTapExpand: () {
            Navigator.of(context).pop(); // Tutup overlay
            Navigator.of(context).push(
              MaterialPageRoute(
                builder:
                    (context) => YoutubeVideoPlayerPage(
                      videoId: widget.videoId,
                      title: widget.title,
                    ),
              ),
            );
          },
          onTapClose: () {
            _controller.dispose();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  void deactivate() {
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (_controller.value.isReady) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Theme.of(context).colorScheme.primary,
        ),
        onReady: () {
          if (!_isFullScreen) {
            _enterFullScreen();
          }
        },
      ),
      builder: (context, player) {
        // Mode fullscreen landscape
        return Scaffold(
          body: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: Center(child: player),
              ),
              Positioned(
                top: 40,
                left: 16,
                child: GestureDetector(
                  onTap: () {
                    _exitToMiniplayer();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MiniPlayerOverlay extends StatelessWidget {
  final YoutubePlayerController controller;
  final String title;
  final VoidCallback onTapExpand;
  final VoidCallback onTapClose;

  const MiniPlayerOverlay({
    super.key,
    required this.controller,
    required this.title,
    required this.onTapExpand,
    required this.onTapClose,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 20),
        child: GestureDetector(
          onTap: onTapExpand,
          child: Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  YoutubePlayer(
                    controller: controller,
                    showVideoProgressIndicator: false,
                  ),
                  // Close button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: onTapClose,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Title overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
