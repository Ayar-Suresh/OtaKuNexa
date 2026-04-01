import 'package:flutter/material.dart';
import 'package:otakunexa/services/api_key_manager.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  final ApiKeyManager apiManager;
  const SplashScreen({super.key, required this.apiManager});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset('assets/videos/splash_video.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });

    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    print("Logical size: ${size.width} x ${size.height}");
    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller.value.isInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(
              color: Colors.black,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.deepPurpleAccent),
              ),
            ),
    );
  }
}
