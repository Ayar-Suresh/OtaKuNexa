class ShortVideo {
  final String videoId;
  final String title;
  final String channel;
  final int likes;
  final int views;

  ShortVideo({
    required this.videoId,
    required this.title,
    required this.channel,
    required this.likes,
    required this.views,
  });

  factory ShortVideo.fromJson(Map<String, dynamic> json) {
    return ShortVideo(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      channel: json['channel'] ?? 'Unknown Channel',
      likes: json['likes'] ?? 0,
      views: json['views'] ?? 0,
    );
  }
}

class FeedItem {
  final ShortVideo? video;
  final bool isAd;

  FeedItem({this.video, this.isAd = false});
}
