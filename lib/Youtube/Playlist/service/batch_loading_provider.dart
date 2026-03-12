import 'package:flutter/foundation.dart';
import 'package:otakunexa/Youtube/Playlist/models/youtube_playlist_model.dart';
import 'package:otakunexa/Youtube/Playlist/service/youtube_offline_playlist.dart';

class PlaylistProvider with ChangeNotifier {
  final List<YoutubePlaylist> _loadedPlaylists = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentIndex = 0;
  final int _batchSize = 50;
  String _searchQuery = '';

  List<YoutubePlaylist> get playlists => _loadedPlaylists;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get loadedCount => _loadedPlaylists.length;

  Future<void> loadInitialPlaylists() async {
    _resetState();
    _isLoading = true;
    notifyListeners();

    await _loadNextBatch();
  }

  // 🔥 UPDATE 3: Method to Refresh and Randomize from UI
  Future<void> refreshAndRandomize() async {
    _isLoading = true;
    notifyListeners();

    // 1. Shuffle the master list in the service
    await PlaylistService.reshufflePlaylists();

    // 2. Reset the provider state (clear current view)
    _resetState();

    // 3. Load the first batch of the NEW random order
    await _loadNextBatch();
  }

  Future<void> loadMorePlaylists() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    await _loadNextBatch();
  }

  Future<void> searchPlaylists(String query) async {
    _searchQuery = query;
    await loadInitialPlaylists();
  }

  Future<void> _loadNextBatch() async {
    try {
      List<YoutubePlaylist> newBatch;

      if (_searchQuery.isEmpty) {
        newBatch = await PlaylistService.getPlaylistsBatch(
          startIndex: _currentIndex,
          batchSize: _batchSize,
        );
      } else {
        newBatch = await PlaylistService.searchPlaylistsBatch(
          query: _searchQuery,
          startIndex: _currentIndex,
          batchSize: _batchSize,
        );
      }

      if (newBatch.isEmpty) {
        _hasMore = false;
      } else {
        _loadedPlaylists.addAll(newBatch);
        _currentIndex += newBatch.length;

        // Check if there's more data
        final totalCount = _searchQuery.isEmpty
            ? await PlaylistService.getTotalCount()
            : await PlaylistService.getSearchCount(_searchQuery);

        _hasMore = _currentIndex < totalCount;
      }
    } catch (e) {
      print('Error loading batch: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetState() {
    _loadedPlaylists.clear();
    _currentIndex = 0;
    _hasMore = true;
    _isLoading = false;
  }

  void clearSearch() {
    _searchQuery = '';
    loadInitialPlaylists();
  }
}
