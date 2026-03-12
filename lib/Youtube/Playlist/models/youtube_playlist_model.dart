class YoutubePlaylistResponse {
  final String kind;
  final String etag;
  final String nextPageToken;
  final PageInfo pageInfo;
  final String contentType;
  final List<YoutubePlaylist> items;

  YoutubePlaylistResponse({
    required this.kind,
    required this.etag,
    required this.nextPageToken,
    required this.pageInfo,
    required this.contentType,
    required this.items,
  });

  factory YoutubePlaylistResponse.fromJson(Map<String, dynamic> json) {
    return YoutubePlaylistResponse(
      contentType: "Youtube",
      kind: json['kind'] ?? '',
      etag: json['etag'] ?? '',
      nextPageToken: json['nextPageToken'] ?? '',
      pageInfo: PageInfo.fromJson(json['pageInfo'] ?? {}),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => YoutubePlaylist.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class PageInfo {
  final int totalResults;
  final int resultsPerPage;

  PageInfo({required this.totalResults, required this.resultsPerPage});

  factory PageInfo.fromJson(Map<String, dynamic> json) {
    return PageInfo(
      totalResults: json['totalResults'] ?? 0,
      resultsPerPage: json['resultsPerPage'] ?? 0,
    );
  }
}

class YoutubePlaylist {
  final String id;
  final String title;
  final String channelId;
  final String thumbnail;
  final int itemCount;

  YoutubePlaylist({
    required this.id,
    required this.title,
    required this.channelId,
    required this.thumbnail,
    required this.itemCount,
  });

  factory YoutubePlaylist.fromJson(Map<String, dynamic> json) {
    return YoutubePlaylist(
      id: json['id'] ?? '',
      title: json['snippet']?['title'] ?? 'No Title',
      channelId: json['snippet']?['channelId'] ?? '',
      thumbnail:
          json['snippet']?['thumbnails']?['medium']?['url'] ??
          json['snippet']?['thumbnails']?['high']?['url'] ??
          '',
      itemCount: json['contentDetails']?['itemCount'] ?? 0,
    );
  }
}
