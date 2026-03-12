class PlaylistItem {
  final String title;
  final String videoId;
  final String publishedAt;

  PlaylistItem({
    required this.title,
    required this.videoId,
    required this.publishedAt,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      title: json['snippet']['title'],
      videoId: json['snippet']['resourceId']['videoId'],
      publishedAt: json['snippet']['publishedAt'],
    );
  }
}

class PlaylistData {
  final List<PlaylistItem> items;

  PlaylistData({required this.items});

  factory PlaylistData.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List)
        .map((item) => PlaylistItem.fromJson(item))
        .toList();

    items.shuffle(); // 🔥 SIMPLE FIX → random order

    return PlaylistData(items: items);
  }
}
