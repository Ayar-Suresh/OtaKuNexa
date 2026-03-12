import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

// --- MODELS ---
class CommunityPost {
  final String id;
  final String title;
  final String body;
  final String author;
  final String upvotes;
  final String commentCount;
  final String? thumbnail; // Main post image
  final bool isOffline;
  final List<String> curatedImages; // For offline "Featured" feel

  CommunityPost({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.upvotes,
    required this.commentCount,
    this.thumbnail,
    this.isOffline = false,
    this.curatedImages = const [],
  });
}

class CommunityComment {
  final String id;
  final String author;
  final String body;
  final String score;
  final bool isOp;
  final List<String> imageUrls; // Images extracted from comment text

  CommunityComment({
    required this.id,
    required this.author,
    required this.body,
    required this.score,
    required this.imageUrls,
    this.isOp = false,
  });
}

// --- SERVICE ---
class RedditService {
  static const String _baseUrl = 'https://www.reddit.com/r/Animesuggest';
  static const Map<String, String> _headers = {
    "User-Agent": "android:com.otakunexa.app:v3.0.0 (by /u/OtakuDev)",
  };

  // State for Infinite Scroll
  String? _afterCursor;
  bool _hasMore = true;
  bool _isRateLimited = false;

  // 1. FETCH POSTS (Handles Pagination & Search)
  Future<List<CommunityPost>> fetchPosts({
    String? query,
    bool isLoadMore = false,
  }) async {
    // Reset state if this is a fresh reload (pull-to-refresh or new search)
    if (!isLoadMore) {
      _afterCursor = null;
      _hasMore = true;
      _isRateLimited = false;
    }

    // Stop if we know there's no more data or we are blocked
    if (isLoadMore && (!_hasMore || _isRateLimited)) return [];

    // Construct URL with Pagination ('after')
    String url = query != null && query.isNotEmpty
        ? '$_baseUrl/search.json?q=$query&restrict_sr=1&sort=relevance&limit=15'
        : '$_baseUrl/hot.json?limit=15';

    if (_afterCursor != null) {
      url += '&after=$_afterCursor';
    }

    try {
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update Cursor
        _afterCursor = data['data']['after'];
        _hasMore = _afterCursor != null;

        final children = data['data']['children'] as List;
        final posts = children.map((json) => _mapToPost(json['data'])).toList();

        // If it's the first load and we got very few results, mix in offline data
        if (!isLoadMore && posts.length < 3) {
          posts.addAll(_getOfflineFallback());
        }

        return posts;
      } else if (response.statusCode == 429) {
        // Rate Limit Hit
        print("⚠️ 429 Rate Limit. Switching to Offline Mode.");
        _isRateLimited = true;
        // Only return offline data if we aren't just scrolling
        return isLoadMore ? [] : _getOfflineFallback();
      }
    } catch (e) {
      print("Network Error: $e");
      if (!isLoadMore) return _getOfflineFallback();
    }
    return [];
  }

  // 2. FETCH COMMENTS (Extracts Images)
  Future<List<CommunityComment>> fetchComments(String postId) async {
    if (postId.startsWith('offline') || _isRateLimited) return [];

    final url =
        "https://www.reddit.com/comments/$postId.json?sort=top&limit=15";

    try {
      final response = await http.get(Uri.parse(url), headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        final commentsData = jsonResponse[1]['data']['children'] as List;

        return commentsData
            .where((c) => c['kind'] != 'more')
            .map((c) => _mapToComment(c['data']))
            .toList();
      }
    } catch (e) {
      print("Error fetching comments: $e");
    }
    return [];
  }

  // --- PARSING LOGIC ---

  CommunityPost _mapToPost(Map<String, dynamic> data) {
    String? thumb;
    // Check for explicit thumbnail or contained image
    if (data['thumbnail'] != null && data['thumbnail'].contains('http')) {
      thumb = data['thumbnail'];
    } else if (data['url_overridden_by_dest'] != null &&
        _isImage(data['url_overridden_by_dest'])) {
      thumb = data['url_overridden_by_dest'];
    }

    return CommunityPost(
      id: data['id'],
      title: data['title'] ?? 'No Title',
      body: data['selftext'] ?? '',
      author: data['author'] ?? 'Unknown',
      upvotes: _formatScore(data['ups']),
      commentCount: "${data['num_comments'] ?? 0}",
      thumbnail: thumb,
      isOffline: false,
    );
  }

  CommunityComment _mapToComment(Map<String, dynamic> data) {
    String body = data['body'] ?? '';
    List<String> images = [];

    // Regex to find image links in text (jpg, png, gif, webp)
    final urlRegExp = RegExp(
      r'(https?://\S+\.(?:jpg|jpeg|png|gif|webp))',
      caseSensitive: false,
    );
    final matches = urlRegExp.allMatches(body);

    for (final match in matches) {
      images.add(match.group(0)!);
    }

    // Remove the raw URLs from text so it looks cleaner
    for (var img in images) {
      body = body.replaceAll(img, '').trim();
    }

    return CommunityComment(
      id: data['id'] ?? 'unknown',
      author: data['author'] ?? '[deleted]',
      body: body,
      score: _formatScore(data['score']),
      isOp: data['is_submitter'] ?? false,
      imageUrls: images,
    );
  }

  bool _isImage(String url) {
    return url.endsWith('.jpg') ||
        url.endsWith('.png') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp');
  }

  String _formatScore(int? score) {
    if (score == null) return "0";
    if (score >= 1000) return "${(score / 1000).toStringAsFixed(1)}k";
    return "$score";
  }

  // 3. CURATED OFFLINE DATA
  List<CommunityPost> _getOfflineFallback() {
    return [
      CommunityPost(
        id: "offline_1",
        title: "Best Anime where MC turns Evil?",
        body:
            "I'm looking for a protagonist who slowly descends into darkness.",
        author: "OtakuSystem",
        upvotes: "12.5k",
        commentCount: "HOT",
        isOffline: true,
        curatedImages: [
          "https://cdn.myanimelist.net/images/anime/9/9453.jpg", // Death Note
          "https://cdn.myanimelist.net/images/anime/10/79352.jpg", // Code Geass
          "https://cdn.myanimelist.net/images/anime/11/39717.jpg", // AoT
        ],
      ),
      CommunityPost(
        id: "offline_2",
        title: "Wholesome Romance (No Drama)",
        body: "Just need something sweet to watch this weekend.",
        author: "NexaBot",
        upvotes: "8.2k",
        commentCount: "PICK",
        isOffline: true,
        curatedImages: [
          "https://cdn.myanimelist.net/images/anime/1208/116938.jpg", // Tonikawa
          "https://cdn.myanimelist.net/images/anime/10/71945.jpg", // Horimiya
        ],
      ),
    ];
  }
}
