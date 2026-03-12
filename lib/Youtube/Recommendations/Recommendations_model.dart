import 'dart:convert';

import 'package:flutter/services.dart';

class Recommendations_Model {
  final String title;
  final String videoId;
  final String thumbnail;
  final String likes;
  final int vidDuration;

  Recommendations_Model({
    required this.title,
    required this.likes,
    required this.thumbnail,
    required this.videoId,
    required this.vidDuration,
  });

  factory Recommendations_Model.fromJson(Map<String, dynamic> json) {
    return Recommendations_Model(
      title: json['title'] ?? 'Anime Recommendation',
      likes: json['likes'] ?? '1000',
      thumbnail: json['thumbnail'],
      videoId: json['videoId'] ?? '',
      vidDuration: json['duration_seconds'],
    );
  }
  static Future<List<Recommendations_Model>> loadFromAssets(String path) async {
    final jsonString = await rootBundle.loadString(path);
    final jsonList = json.decode(jsonString) as List;

    return jsonList.map((e) => Recommendations_Model.fromJson(e)).toList();
  }
}
