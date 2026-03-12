import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:otakunexa/Youtube/Recommendations/recommendations_model.dart';

class VideoController {
  final int batchSize = 10;

  List<Recommendations_Model> allVideos = [];
  List<Recommendations_Model> displayedVideos = [];

  bool isLoadingMore = false;

  // Load JSON file
  Future<List<Recommendations_Model>> loadOfflineVideos() async {
    final jsonString = await rootBundle.loadString(
      'assets/content/anime_recommendation.json',
    );
    final jsonList = json.decode(jsonString) as List;

    return jsonList.map((e) => Recommendations_Model.fromJson(e)).toList();
  }

  // Initialize controller
  Future<void> initialize() async {
    allVideos = await loadOfflineVideos();
    allVideos.shuffle(Random());
    displayedVideos = allVideos.take(batchSize).toList();
  }

  // Load more videos
  Future<void> loadMore() async {
    if (isLoadingMore) return;

    isLoadingMore = true;

    await Future.delayed(const Duration(milliseconds: 500));

    final currentLength = displayedVideos.length;

    if (currentLength < allVideos.length) {
      final nextItems = allVideos.skip(currentLength).take(batchSize).toList();
      displayedVideos.addAll(nextItems);
    }

    isLoadingMore = false;
  }
}
