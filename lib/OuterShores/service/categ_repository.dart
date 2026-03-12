import 'dart:convert';
import 'dart:math';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnimeRepository {
  // ===========================================================================
  // 🔒 LAYER 1: FRONT LINE
  // ===========================================================================
  static final List<String> _encodedUserPool = [
    "YXlhcnNidXNpbmVzcy1ib3Q=",
    "b3Rha3VoZXJvOTktbGFuZw==",

    "T3RhS3VOZXhh",

    "Q3liZXJEcmlmdDAw",
  ];

  static const String _repoName = 'anime-index';
  static const String _fileName = 'recent_added_category.json';

  static String _constructUrl(String encodedUser) {
    try {
      String decodedUser = utf8.decode(base64.decode(encodedUser));
      return "https://raw.githubusercontent.com/$decodedUser/$_repoName/main/$_fileName";
    } catch (e) {
      return "";
    }
  }

  // ===========================================================================
  // 👻 LAYER 3: GHOST PROTOCOL (Shared Identity)
  // ===========================================================================
  static String _generateGhostIdentity(int version) {
    int num1 = (version == 1) ? 0 : version;
    int num2 = (version % 2 == 0) ? 0 : (version - 1);
    int v = version - 1;
    int suffix = 6814 + (v * 19) + (v * v * 7);
    return "OtexSever${num1}LogK${num2}TNENGQ$suffix";
  }

  // 💾 CACHE KEYS (Shared with DownloadService)
  static const String _cacheKey = 'cached_recent_updates';
  static const String _timeKey = 'cached_recent_time';
  static const String _versionKey = 'active_ghost_version'; // 🗝️ SHARED MEMORY
  static const String _laneKey = 'user_traffic_lane';
  static const Duration _cacheDuration = Duration(hours: 6);

  // ===========================================================================
  // ⚙️ MAIN LOGIC
  // ===========================================================================
  Future<List<AnimeData>> getAnimeByCategory(String category) async {
    if (category == 'recent_added_category') {
      return await _fetchWithWaterfallStrategy();
    }
    return await _loadFromLocalAssets(category);
  }

  Future<List<AnimeData>> _fetchWithWaterfallStrategy() async {
    final prefs = await SharedPreferences.getInstance();

    // 1️⃣ CHECK CACHE
    final String? cachedJson = prefs.getString(_cacheKey);
    final int? lastTime = prefs.getInt(_timeKey);
    if (cachedJson != null && lastTime != null) {
      if (DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(lastTime),
          ) <
          _cacheDuration) {
        return _parseJson(cachedJson);
      }
    }

    // 2️⃣ LAYER 1: HARDCODED LOAD BALANCER
    List<String> pool = List.from(_encodedUserPool)..shuffle();
    for (String encodedUser in pool) {
      String url = _constructUrl(encodedUser);
      if (url.isEmpty) continue;
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          await _saveCache(prefs, res.body);
          return _parseJson(res.body);
        }
      } catch (e) {}
    }

    // 3️⃣ LAYER 2: FIREBASE REMOTE CONFIG
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.fetchAndActivate();

      String poolString = remoteConfig.getString('server_pool_v1');
      if (poolString.isNotEmpty) {
        final data = json.decode(poolString);
        if (data['maintenance_mode'] != true) {
          List<dynamic> mirrors = data['mirrors'];
          mirrors.shuffle();
          for (var mirror in mirrors) {
            try {
              final res = await http.get(Uri.parse(mirror['category_url']));
              if (res.statusCode == 200) {
                await _saveCache(prefs, res.body);
                return _parseJson(res.body);
              }
            } catch (e) {}
          }
        }
      }
    } catch (e) {}

    // 4️⃣ 👻 LAYER 3: GHOST PROTOCOL (LANE HUNTER)
    // Only runs if Layer 1 & 2 fail.

    // A. Check Shared Saved Version First (Fast Track)
    // If DownloadService found a working version, use it here too!
    int savedVersion = prefs.getInt(_versionKey) ?? -1;
    if (savedVersion != -1) {
      if (await _tryGhostVersion(savedVersion, prefs)) {
        return _parseJson(prefs.getString(_cacheKey)!);
      }
    }

    // B. Start Hunting (Exact same logic as DownloadService)
    int userLane = prefs.getInt(_laneKey) ?? (Random().nextInt(5) + 1);
    await prefs.setInt(_laneKey, userLane);

    int baseStart = userLane * 10;

    // Try up to 40 tiers (covering range up to 2000+)
    for (int tier = 0; tier < 40; tier++) {
      int currentBase = baseStart + (tier * 50);

      if (currentBase > 2000) break; // Safety Limit

      // In each batch, try 4 sequential IDs
      for (int i = 0; i < 4; i++) {
        int v = currentBase + i;

        if (await _tryGhostVersion(v, prefs)) {
          // 🎉 Found! Save version to Shared Memory
          await prefs.setInt(_versionKey, v);
          return _parseJson(prefs.getString(_cacheKey)!);
        }
      }
    }

    // Fallback to old cache
    if (cachedJson != null) return _parseJson(cachedJson);
    return [];
  }

  // --- Helper: Try Ghost Version ---
  static Future<bool> _tryGhostVersion(int v, SharedPreferences prefs) async {
    try {
      String identity = _generateGhostIdentity(v);
      // NOTE: Different Repo for Metadata (daily-kaam-logs)
      String url =
          "https://raw.githubusercontent.com/$identity/daily-kaam-logs/main/work/sys_patch.json";

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        await _saveCache(prefs, response.body);
        return true;
      }
    } catch (e) {}
    return false;
  }

  static Future<void> _saveCache(
    SharedPreferences prefs,
    String jsonBody,
  ) async {
    await prefs.setString(_cacheKey, jsonBody);
    await prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<AnimeData>> _loadFromLocalAssets(String category) async {
    try {
      String jsonString = await rootBundle.loadString(
        'assets/content/category/$category.json',
      );
      return _parseJson(jsonString);
    } catch (e) {
      return [];
    }
  }

  List<AnimeData> _parseJson(String jsonString) {
    try {
      final jsonResponse = json.decode(jsonString);
      if (jsonResponse is List) {
        return jsonResponse
            .map((item) => AnimeModel.fromJson(item).data)
            .toList();
      } else if (jsonResponse['data'] is List) {
        return (jsonResponse['data'] as List)
            .map((item) => AnimeModel.fromJson(item).data)
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AnimeData?> getAnimeById(int id, String category) async {
    final all = await getAnimeByCategory(category);
    if (all.isEmpty) return null;
    try {
      return all.firstWhere((a) => a.malId == id);
    } catch (e) {
      return null;
    }
  }
}
