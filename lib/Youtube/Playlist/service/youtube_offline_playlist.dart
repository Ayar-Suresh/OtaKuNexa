import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:otakunexa/Youtube/Playlist/models/youtube_playlist_model.dart';

class PlaylistService {
  static List<YoutubePlaylist> _allPlaylists = [];
  static bool _isInitialized = false;

  // Initialize and load all data once
  static Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/content/animes.json',
      );

      // Parse as List<dynamic> since your JSON is an array
      final List<dynamic> jsonArray = json.decode(jsonString);

      // Extract playlists from each response object
      _allPlaylists = [];

      for (var responseObj in jsonArray) {
        if (responseObj['items'] != null) {
          final List<dynamic> items = responseObj['items'];
          for (var item in items) {
            _allPlaylists.add(YoutubePlaylist.fromJson(item));
          }
        }
      }

      // 🔥 UPDATE 1: Randomize the order immediately on first load
      _allPlaylists.shuffle();

      _isInitialized = true;
      print(
        '✅ Successfully loaded and randomized ${_allPlaylists.length} playlists',
      );

      // Debug: Print first few titles
      if (_allPlaylists.isNotEmpty) {
        for (
          int i = 0;
          i < (_allPlaylists.length > 3 ? 3 : _allPlaylists.length);
          i++
        ) {
          print('🎬 Playlist ${i + 1}: ${_allPlaylists[i].title}');
        }
      }
    } catch (e) {
      print('❌ Error loading playlists: $e');
      _allPlaylists = [];
      _isInitialized = true;
    }
  }

  // 🔥 UPDATE 2: New Method to reshuffle existing data without reloading file
  static Future<void> reshufflePlaylists() async {
    if (!_isInitialized) await _initialize();

    // Randomizes the list in memory
    _allPlaylists.shuffle();
    print('🔀 Playlists have been reshuffled!');
  }

  // Get batches of data
  static Future<List<YoutubePlaylist>> getPlaylistsBatch({
    required int startIndex,
    required int batchSize,
  }) async {
    if (!_isInitialized) {
      await _initialize();
    }

    final endIndex = startIndex + batchSize;
    if (startIndex >= _allPlaylists.length) {
      return [];
    }

    final actualEndIndex = endIndex > _allPlaylists.length
        ? _allPlaylists.length
        : endIndex;

    return _allPlaylists.sublist(startIndex, actualEndIndex);
  }

  // Get total count
  static Future<int> getTotalCount() async {
    if (!_isInitialized) {
      await _initialize();
    }
    return _allPlaylists.length;
  }

  // Search with batch loading
  static Future<List<YoutubePlaylist>> searchPlaylistsBatch({
    required String query,
    required int startIndex,
    required int batchSize,
  }) async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (query.isEmpty) {
      return getPlaylistsBatch(startIndex: startIndex, batchSize: batchSize);
    }

    final filteredPlaylists = _allPlaylists
        .where(
          (playlist) =>
              playlist.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();

    final endIndex = startIndex + batchSize;
    if (startIndex >= filteredPlaylists.length) {
      return [];
    }

    final actualEndIndex = endIndex > filteredPlaylists.length
        ? filteredPlaylists.length
        : endIndex;

    return filteredPlaylists.sublist(startIndex, actualEndIndex);
  }

  static Future<int> getSearchCount(String query) async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (query.isEmpty) return _allPlaylists.length;

    return _allPlaylists
        .where(
          (playlist) =>
              playlist.title.toLowerCase().contains(query.toLowerCase()),
        )
        .length;
  }
}
