import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:otakunexa/youtube/Episodes/model/playlist_item.dart';

class PlaylistJsonService {
  static final PlaylistJsonService _instance = PlaylistJsonService._internal();
  factory PlaylistJsonService() => _instance;
  PlaylistJsonService._internal();

  static const String _jsonPath = 'assets/content/playlist_video.json';
  Map<String, PlaylistData>? _cachedData;

  Future<Map<String, PlaylistData>> loadPlaylistData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final String jsonString = await rootBundle.loadString(_jsonPath);
      // Run json.decode in a background isolate to prevent UI freezing
      final Map<String, dynamic> jsonData = await compute(jsonDecode, jsonString) as Map<String, dynamic>;

      _cachedData = {};
      jsonData.forEach((playlistId, playlistJson) {
        _cachedData![playlistId] = PlaylistData.fromJson(playlistJson);
      });

      return _cachedData!;
    } catch (e) {
      print('Error loading JSON data: $e');
      return {};
    }
  }

  List<PlaylistItem>? getPlaylistItems(String playlistId) {
    return _cachedData?[playlistId]?.items;
  }

  void clearCache() {
    _cachedData = null;
  }
}
