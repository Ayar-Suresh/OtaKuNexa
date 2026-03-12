import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubeController {
  final YoutubePlayerController player;

  YoutubeController(String videoId)
    : player = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
      );

  void loadVideo(String videoId) {
    player.load(videoId);
    player.play();
  }

  void dispose() {
    player.dispose();
  }
}
