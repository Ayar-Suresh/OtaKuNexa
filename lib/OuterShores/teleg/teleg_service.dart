import 'dart:convert';
import 'dart:math';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:showcaseview/showcaseview.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';

// =============================================================================
// 🧠 LOGIC CLASS: ANIME DOWNLOAD SERVICE
// =============================================================================
class AnimeDownloadService {
  static String? _activeBotUsername;
  static String _currentServerName = "Auto";

  // Track connection status for UI Button Logic
  static bool _isConnectionStable = false;

  // 💾 CACHE CONFIGURATION
  static const String _cacheKey = 'cached_anime_index_json';
  static const String _timeKey = 'cached_anime_index_time';

  // 🔥 SHARED MEMORY KEYS
  static const String _homeCacheKey = 'cached_recent_updates';
  static const String _homeTimeKey = 'cached_recent_time';
  static const String _versionKey = 'active_ghost_version';
  static const String _laneKey = 'user_traffic_lane';

  static const String _updatePromptKey = 'last_update_prompt_timestamp';
  static const Duration _cacheDuration = Duration(hours: 12);

  static const String _defaultBot = "file_share_ota_bot";

  // 🔒 LAYER 1: HARDCODED POOL
  static final List<String> _encodedUserPool = [
    "YXlhcnNidXNpbmVzcy1ib3Q=",
    "b3Rha3VoZXJvOTktbGFuZw==",

    "T3RhS3VOZXhh",

    "Q3liZXJEcmlmdDAw",
  ];

  static const String _repoName = 'anime-index';
  static const String _fileName = 'anime_index.json';

  static String _constructUrl(String encodedUser) {
    try {
      String decodedUser = utf8.decode(base64.decode(encodedUser));
      return "https://raw.githubusercontent.com/$decodedUser/$_repoName/main/$_fileName";
    } catch (e) {
      return "";
    }
  }

  // 👻 GHOST IDENTITY GENERATOR
  static String _generateGhostIdentity(int version) {
    int num1 = (version == 1) ? 0 : version;
    int num2 = (version % 2 == 0) ? 0 : (version - 1);
    int v = version - 1;
    int suffix = 6814 + (v * 19) + (v * v * 7);
    return "OtexSever${num1}LogK${num2}TNENGQ$suffix";
  }

  // 🏷️ SERVER NAME DISPLAY
  static String _getServerDisplayName(int version) {
    if (version < 50) return "Server A (V$version)";
    if (version < 100) return "Server B (V$version)";
    if (version < 150) return "Server C (V$version)";
    if (version < 200) return "Server D (V$version)";
    return "Server X (V$version)";
  }

  static String get currentServerName => _currentServerName;

  // ===========================================================================
  // ⚙️ MAIN ENTRY POINT
  // ===========================================================================
  static Future<Map<String, dynamic>?> checkAvailability(
    String malId, {
    BuildContext? context,
  }) async {
    String? jsonBody = await _fetchJsonBody(context: context);
    if (jsonBody != null) {
      _isConnectionStable = true;
      return _parseAndFind(
        jsonBody,
        malId,
        layerDefaultBot: _activeBotUsername ?? _defaultBot,
      );
    } else {
      _isConnectionStable = false;
      if (context != null && context.mounted) _showFailurePrompt(context);
    }
    return null;
  }

  // ===========================================================================
  // 🌊 WATERFALL FETCH SYSTEM
  // ===========================================================================
  static Future<String?> _fetchJsonBody({
    bool forceRefresh = false,
    BuildContext? context,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    int savedV = prefs.getInt(_versionKey) ?? 0;
    if (savedV > 0) _currentServerName = _getServerDisplayName(savedV);

    final String? cachedJson = prefs.getString(_cacheKey);
    final int? lastTime = prefs.getInt(_timeKey);
    if (!forceRefresh && cachedJson != null && lastTime != null) {
      if (DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(lastTime),
          ) <
          _cacheDuration) {
        _isConnectionStable = true;
        return cachedJson;
      }
    }

    // LAYER 1
    List<String> pool = List.from(_encodedUserPool)..shuffle();
    for (String encodedUser in pool) {
      String url = _constructUrl(encodedUser);
      if (url.isEmpty) continue;
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          await _saveCache(prefs, res.body);
          _activeBotUsername = _defaultBot;
          _currentServerName = "Official";
          return res.body;
        }
      } catch (e) {}
    }

    // LAYER 2
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
              final res = await http.get(Uri.parse(mirror['index_url']));
              if (res.statusCode == 200) {
                await _saveCache(prefs, res.body);
                _activeBotUsername = mirror['bot'];
                _currentServerName = "Cloud";
                return res.body;
              }
            } catch (e) {}
          }
        }
      }
    } catch (e) {}

    // LAYER 3
    print('⚠️ Engaging GHOST PROTOCOL (Lane Hunter)...');
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connecting to Backup Servers..."),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }

    int savedVersion = prefs.getInt(_versionKey) ?? -1;
    if (savedVersion != -1) {
      if (await _tryGhostVersion(savedVersion, prefs)) {
        return prefs.getString(_cacheKey);
      }
    }

    int userLane = prefs.getInt(_laneKey) ?? (Random().nextInt(5) + 1);
    await prefs.setInt(_laneKey, userLane);
    _currentServerName = "Hunting (Lane $userLane)...";
    int baseStart = userLane * 10;

    for (int tier = 0; tier < 40; tier++) {
      int currentBase = baseStart + (tier * 50);
      if (currentBase > 2000) break;
      for (int i = 0; i < 10; i++) {
        int v = currentBase + i;
        if (await _tryGhostVersion(v, prefs)) return prefs.getString(_cacheKey);
      }
    }

    if (cachedJson != null) {
      _isConnectionStable = true;
      return cachedJson;
    }
    return null;
  }

  static Future<bool> _tryGhostVersion(int v, SharedPreferences prefs) async {
    try {
      String identity = _generateGhostIdentity(v);
      String url =
          "https://raw.githubusercontent.com/$identity/project-store-v9/main/assets/texture_map.json";
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        await _saveCache(prefs, response.body);
        await prefs.setInt(_versionKey, v);
        _activeBotUsername = "${identity}_bot";
        _currentServerName = _getServerDisplayName(v);
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

  static Future<bool> shouldShowSwitchButton() async => !_isConnectionStable;

  static Future<bool> openManualServerDialog(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ManualServerDialog(),
    );
    return result == true;
  }

  static void _showFailurePrompt(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text(
          "Connection Failed",
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          "We couldn't connect automatically. Please check our website for a Server ID.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openManualServerDialog(context);
            },
            child: const Text("Enter Manual ID"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic>? _parseAndFind(
    String jsonBody,
    String malId, {
    required String layerDefaultBot,
  }) {
    try {
      final Map<String, dynamic> fullIndex = json.decode(jsonBody);
      String selectedBot = layerDefaultBot;
      if (fullIndex.containsKey('config')) {
        var config = fullIndex['config'];
        if (config != null && config['override_bot'] != null) {
          String override = config['override_bot'].toString();
          if (override.isNotEmpty && override.toLowerCase() != "null") {
            selectedBot = override;
          }
        }
      }
      _activeBotUsername = selectedBot;
      for (String title in fullIndex.keys) {
        if (title == 'config') continue;
        final seasonsData = fullIndex[title]['seasons'] as Map<String, dynamic>;
        bool matchFound = false;

        // 🔥 UPDATE: Check MAL IDs which are at the Season Root Level now
        seasonsData.forEach((seasonKey, seasonValue) {
          if (seasonValue['mal_ids'] != null) {
            List<dynamic> ids = seasonValue['mal_ids'];
            // Check both string and int matches to be safe
            if (ids.contains(malId) ||
                ids.contains(int.tryParse(malId)) ||
                ids.contains(malId.toString())) {
              matchFound = true;
            }
          }
        });
        if (matchFound) return {"data": fullIndex[title], "titleKey": title};
      }
    } catch (e) {}
    return null;
  }

  // UPDATE CHECKER
  static Future<void> checkForUpdate(BuildContext context) async {
    String? jsonBody = await _fetchJsonBody(forceRefresh: true);
    if (jsonBody == null) return;
    try {
      final Map<String, dynamic> fullIndex = json.decode(jsonBody);
      if (fullIndex.containsKey('config')) {
        var config = fullIndex['config'];
        if (config['app_update'] != null) {
          var updateInfo = config['app_update'];
          String latestVersion = updateInfo['latest_version'] ?? "1.0.0";
          String downloadUrl = updateInfo['download_url'] ?? "";
          String changelog = updateInfo['changelog'] ?? "Updates available.";
          bool force = updateInfo['force_update'] ?? false;
          PackageInfo packageInfo = await PackageInfo.fromPlatform();
          if (_isVersionNewer(packageInfo.version, latestVersion)) {
            if (force && context.mounted) {
              _showUpdateDialog(
                context,
                latestVersion,
                changelog,
                downloadUrl,
                true,
              );
            } else if (await _shouldShowSoftUpdatePrompt() && context.mounted) {
              _showUpdateDialog(
                context,
                latestVersion,
                changelog,
                downloadUrl,
                false,
              );
            }
          }
        }
      }
    } catch (e) {}
  }

  static bool _isVersionNewer(String current, String latest) {
    List<int> curr = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> lat = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (int i = 0; i < lat.length; i++) {
      int c = (i < curr.length) ? curr[i] : 0;
      if (lat[i] > c) return true;
      if (lat[i] < c) return false;
    }
    return false;
  }

  static Future<bool> _shouldShowSoftUpdatePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    int? last = prefs.getInt(_updatePromptKey);
    if (last == null) return true;
    return DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(last))
            .inHours >=
        24;
  }

  static Future<void> _markUpdateAsIgnored() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_updatePromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  static void _showUpdateDialog(
    BuildContext context,
    String version,
    String changelog,
    String url,
    bool force,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !force,
      builder: (ctx) => UpdateDialog(
        version: version,
        changelog: changelog,
        downloadUrl: url,
        isForceUpdate: force,
        onIgnored: () => _markUpdateAsIgnored(),
      ),
    );
  }

  static Future<void> openTelegramBatch(
    BuildContext context,
    String titleKey,
    String season,
    String batchKey,
  ) async {
    String targetBot = _activeBotUsername ?? _defaultBot;
    String rawPayload = "$titleKey|$season|$batchKey";
    Codec<String, String> stringToBase64 = utf8.fuse(base64Url);
    String encodedPayload = stringToBase64.encode(rawPayload);
    final Uri url = Uri.parse("https://t.me/$targetBot?start=$encodedPayload");
    try {
      if (!await url_launcher.launchUrl(
        url,
        mode: url_launcher.LaunchMode.externalApplication,
      )) {
        throw 'Err';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Could not open Telegram")));
    }
  }
}

// =============================================================================
// 🎨 UI: MANUAL SERVER DIALOG
// =============================================================================
class ManualServerDialog extends StatefulWidget {
  const ManualServerDialog({super.key});
  @override
  State<ManualServerDialog> createState() => _ManualServerDialogState();
}

class _ManualServerDialogState extends State<ManualServerDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;

  Future<void> _verifyAndConnect() async {
    String input = _controller.text.trim();
    if (input.isEmpty) return;
    int? version = int.tryParse(input);
    if (version == null || version < 1 || version > 2000) {
      setState(() => _statusMessage = "Please enter valid version (1-2000)");
      return;
    }
    setState(() {
      _isLoading = true;
      _statusMessage = "Connecting to V$version...";
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AnimeDownloadService._cacheKey);
    await prefs.remove(AnimeDownloadService._timeKey);
    bool success = await AnimeDownloadService._tryGhostVersion(version, prefs);
    if (success) {
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Connected!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
        _statusMessage = "❌ Connection Failed.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Manual Server Connect",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ex: 21...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
            if (_statusMessage != null) ...[
              SizedBox(height: 10.h),
              Text(
                _statusMessage!,
                style: TextStyle(
                  color: _statusMessage!.startsWith("❌")
                      ? Colors.red
                      : Colors.blue,
                  fontSize: 12.sp,
                ),
              ),
            ],
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: _isLoading ? null : _verifyAndConnect,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🎨 UI: ANIME DOWNLOAD WIDGET (UPDATED FOR MULTI-LANGUAGE & STRING SEASONS)
// =============================================================================
class AnimeDownloadWidget extends StatefulWidget {
  final Map<String, dynamic> animeData;
  final String titleKey;
  final Function(String selectedSeason) onSeasonChanged;
  final GlobalKey? languageKey;
  final GlobalKey? batchKey;

  const AnimeDownloadWidget({
    super.key,
    required this.animeData,
    required this.titleKey,
    required this.onSeasonChanged,
    this.languageKey,
    this.batchKey,
  });

  @override
  State<AnimeDownloadWidget> createState() => _AnimeDownloadWidgetState();
}

class _AnimeDownloadWidgetState extends State<AnimeDownloadWidget>
    with WidgetsBindingObserver {
  // 📆 Season State
  List<String> _availableSeasons = [];
  String _selectedSeason = "";

  // 🗣️ Language State (New)
  List<String> _availableLanguages = [];
  String _selectedLanguage = "";

  bool _showSwitchButton = false;

  // 🔒 Logic for "Ad Redirect"
  String? _pendingBatchKey;
  DateTime? _adStartTime;
  bool _isProcessingDownload = false;

  static const String _adsterraLink =
      "https://www.effectivegatecpm.com/j7w9ucfu?key=702b3a8a2b0287aec2efeb78306a5d1e";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initSeasons();
    _checkSwitchButtonVisibility();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🧠 LIFECYCLE LISTENER
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pendingBatchKey != null &&
        _adStartTime != null) {
      final timeSpent = DateTime.now().difference(_adStartTime!);
      final batchToOpen = _pendingBatchKey!;

      setState(() {
        _pendingBatchKey = null;
        _adStartTime = null;
        _isProcessingDownload = false;
      });

      if (timeSpent.inSeconds >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thanks for supporting! Opening Telegram... 🚀"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(milliseconds: 300), () {
          AnimeDownloadService.openTelegramBatch(
            context,
            widget.titleKey,
            _selectedSeason,
            batchToOpen,
          );
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please stay on the ad for 10 seconds to complete verification.",
            ),
            backgroundColor: Color.fromARGB(255, 236, 16, 0),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _checkSwitchButtonVisibility() async {
    bool show = await AnimeDownloadService.shouldShowSwitchButton();
    if (mounted) setState(() => _showSwitchButton = show);
  }

  // 🔥 UPDATED: Initialize Seasons with Safe Sorting
  void _initSeasons() {
    final seasonsData = widget.animeData['seasons'] as Map<String, dynamic>;
    _availableSeasons = seasonsData.keys.toList();

    // 🔥 NEW: Safe Sorting (Handle Numbers vs Strings)
    _availableSeasons.sort((a, b) {
      final int? numA = int.tryParse(a);
      final int? numB = int.tryParse(b);

      if (numA != null && numB != null) {
        return numA.compareTo(numB); // Both are numbers
      } else if (numA != null) {
        return -1; // Numbers come before strings
      } else if (numB != null) {
        return 1; // Strings come after numbers
      } else {
        return a.compareTo(b); // Alphabetical sort for strings
      }
    });

    if (_availableSeasons.isNotEmpty) {
      _selectedSeason = _availableSeasons.first;
      _updateLanguagesForSeason(
        _selectedSeason,
      ); // Update langs for current season

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSeasonChanged(_selectedSeason);
      });
    }
  }

  // 🔥 NEW: Logic to extract languages from the new JSON structure
  void _updateLanguagesForSeason(String season) {
    final seasonData = widget.animeData['seasons'][season];

    // Check if we are using NEW STRUCTURE (languages key exists)
    if (seasonData != null && seasonData.containsKey('languages')) {
      final langMap = seasonData['languages'] as Map<String, dynamic>;
      _availableLanguages = langMap.keys.toList();
      _availableLanguages.sort(); // Alphabetical sort
    } else {
      // BACKWARD COMPATIBILITY: OLD JSON STRUCTURE
      // If 'languages' key missing, treat 'Unknown' or 'Default' as language
      _availableLanguages = ["Default"];
    }

    if (_availableLanguages.isNotEmpty) {
      _selectedLanguage = _availableLanguages.first;
    } else {
      _selectedLanguage = "";
    }
  }

  void _handleManualSwitch() async {
    final bool refreshed = await AnimeDownloadService.openManualServerDialog(
      context,
    );
    if (refreshed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Server Changed! Reloading..."),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _openSafeBrowser(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: Colors.black,
            navigationBarColor: Colors.black,
          ),
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,
          animations: CustomTabsSystemAnimations.slideIn(),
        ),
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: Colors.black,
          preferredControlTintColor: Colors.deepPurpleAccent,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      await url_launcher.launchUrl(
        Uri.parse(url),
        mode: url_launcher.LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _handleDownloadFlow(String batchKey) async {
    if (_isProcessingDownload) return;

    bool? userAgreed = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdSupportDialog(),
    );
    if (userAgreed != true) return;

    setState(() {
      _isProcessingDownload = true;
      _pendingBatchKey = batchKey;
      _adStartTime = DateTime.now();
    });

    await _openSafeBrowser(_adsterraLink);
  }

  @override
  Widget build(BuildContext context) {
    final seasonData = widget.animeData['seasons'][_selectedSeason];

    // 🔥 DETERMINE BATCHES BASED ON STRUCTURE
    Map<String, dynamic> batches = {};
    Map<String, dynamic> specials = {};

    if (seasonData != null) {
      if (seasonData.containsKey('languages') &&
          _selectedLanguage != "Default") {
        // NEW STRUCTURE
        final langData = seasonData['languages'][_selectedLanguage];
        if (langData != null) {
          batches = langData['batches'] as Map<String, dynamic>? ?? {};
          specials = langData['specials'] as Map<String, dynamic>? ?? {};
        }
      } else {
        // OLD STRUCTURE (Fallback)
        batches = seasonData['batches'] as Map<String, dynamic>? ?? {};
        specials = seasonData['specials'] as Map<String, dynamic>? ?? {};
      }
    }

    // Sort Keys
    final List<String> standardBatchKeys = batches.keys
        .where((k) => k != 'batch_uncategorized')
        .toList();
    standardBatchKeys.sort((a, b) {
      int numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      int numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    // 🔥 GHOST AUTOMATION EXECUTION
    if (SassyAiService.instance.isGhostNavigating && standardBatchKeys.isNotEmpty) {
      SassyAiService.instance.isGhostNavigating = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Wait for the scrolling animation from AnimeAboutPage to finish
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) {
            SassyAiService.instance.showMessage(
              "now i cant help after this you are going to redirect direct link which makes some money for me and i get motivated to emprove otakunexa and provide you more content so in there you have stay 10 sec and then press back you are automatically going to redirect telegram bot after you press back button and enjoy you anime without frustration ✨",
            );
            _handleDownloadFlow(standardBatchKeys.first);
          }
        });
      });
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Episodes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_showSwitchButton)
                GestureDetector(
                  onTap: _handleManualSwitch,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: Colors.redAccent),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange,
                          size: 12.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          "Fix Server",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    AnimeDownloadService._currentServerName,
                    style: TextStyle(color: Colors.white38, fontSize: 10.sp),
                  ),
                ),
            ],
          ),

          SizedBox(height: 16.h),
          // ⚠️ BATCHING WARNING
          Container(
            margin: EdgeInsets.only(bottom: 16.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1.w,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.amberAccent,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.sp,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text:
                              "Batching is automated and may be imperfect. If episodes are missing, please ",
                        ),
                        TextSpan(
                          text: "check other batches",
                          style: TextStyle(
                            color: Colors.amber[100],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: " or look for "),
                        TextSpan(
                          text: "Mirror Seasons (e.g. S1 Mirror)",
                          style: TextStyle(
                            color: Colors.amber[100],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(
                          text: ". If still not found, message us in the ",
                        ),
                        TextSpan(
                          text: "@OtakuNexa community",
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: "."),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 1️⃣ SEASON SELECTOR (Dynamic Labeling)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _availableSeasons.map((season) {
                bool isSelected = _selectedSeason == season;
                // 🔥 DISPLAY LOGIC: If number, add "Season". If text, show text.
                String labelText = int.tryParse(season) != null
                    ? "Season $season"
                    : season;

                return Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: ChoiceChip(
                    label: Text(labelText),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedSeason = season;
                          _updateLanguagesForSeason(season); // Update Langs
                        });
                        widget.onSeasonChanged(season);
                      }
                    },
                    selectedColor: Colors.deepPurple,
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.sp,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 2️⃣ LANGUAGE SELECTOR (Glass & Tech Style)
          if (_availableLanguages.isNotEmpty &&
              !(_availableLanguages.length == 1 &&
                  _availableLanguages[0] == "Default")) ...[
            SizedBox(height: 16.h),
            Showcase(
              key: widget.languageKey ?? GlobalKey(),
              description: 'Select your language (Sub/Dub)',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
              child: Row(
                children: _availableLanguages.map((lang) {
                  bool isSelected = _selectedLanguage == lang;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLanguage = lang;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          // 💎 GLASS EFFECT: Semi-transparent fill
                          color: isSelected
                              ? Colors.deepPurpleAccent.withOpacity(
                                  0.2,
                                ) // Subtle Purple Tint
                              : Colors.white.withOpacity(
                                  0.03,
                                ), // Very faint Grey
                          // 📏 BORDER: Sharp outline for tech feel
                          border: Border.all(
                            color: isSelected
                                ? Colors
                                      .deepPurpleAccent // Bright Purple Border
                                : Colors.white.withOpacity(
                                    0.1,
                                  ), // Dim Grey Border
                            width: 1.w,
                          ),
                          borderRadius: BorderRadius.circular(
                            12.r,
                          ), // Slightly squared (Techy)
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Dot Indicator for selected state
                            if (isSelected) ...[
                              Container(
                                width: 6.w,
                                height: 6.w,
                                decoration: const BoxDecoration(
                                  color: Colors.deepPurpleAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                            ],
                            Text(
                              lang,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 12.sp,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            ),
          ],

          SizedBox(height: 20.h),

          // 3️⃣ BATCH BUTTONS
          if (batches.isEmpty && specials.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    color: Colors.white24,
                    size: 40.sp,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "No Episodes for $_selectedLanguage",
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ],
              ),
            ),

          Showcase(
            key: widget.batchKey ?? GlobalKey(),
            description: 'Tap a batch to download',
            child: Wrap(
              spacing: 12.w,
              runSpacing: 12.h,
            children: [
              ...standardBatchKeys.map((batchKey) {
                int count = (batches[batchKey] as List).length;
                String label = batchKey
                    .replaceAll("batch", "Batch ")
                    .toUpperCase();
                return _buildBatchButton(
                  label,
                  "$count Episodes",
                  Icons.folder_zip,
                  () => _handleDownloadFlow(batchKey),
                );
              }),
              if (batches.containsKey('batch_uncategorized'))
                Builder(
                  builder: (context) {
                    return _buildBatchButton(
                      "Complete Series / Specials",
                      "${(batches['batch_uncategorized'] as List).length} Files",
                      Icons.snippet_folder_rounded,

                      () => _handleDownloadFlow("batch_uncategorized"),
                    );
                  },
                ),
              if (specials.isNotEmpty)
                _buildBatchButton(
                  "SPECIALS",
                  "${specials.length} Files",
                  Icons.star,
                  () => _handleDownloadFlow("Special_1"),
                ),
            ],
          ),
          ),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildBatchButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: _isProcessingDownload ? null : onTap,
      child: Opacity(
        opacity: _isProcessingDownload ? 0.5 : 1.0,
        child: Container(
          width: MediaQuery.sizeOf(context).width / 3 - 25.w,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.deepPurpleAccent, size: 28.sp),
              SizedBox(height: 8.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 10.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 🥺 AD SUPPORT DIALOG
// =============================================================================
class AdSupportDialog extends StatelessWidget {
  const AdSupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E2C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80.h,
              width: 80.h,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                color: Colors.pinkAccent,
                size: 40.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Wait! 🛑 The Servers are Hungry!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 13.sp,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "I know ads are annoying. But running "),
                  TextSpan(
                    text: "OtakuNexa",
                    style: TextStyle(
                      color: Colors.deepPurpleAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text:
                        " isn't free (my wallet is crying 😭). \n\nJust visit this link for ",
                  ),
                  TextSpan(
                    text: "a few seconds",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text:
                        " to help keep the lights on. It’s a small step for you, but a giant leap for our survival! 🚀",
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurpleAccent,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  "Okay, I'll Help! 😤❤️",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Text(
                "No, I hate you.",
                style: TextStyle(color: Colors.white24, fontSize: 12.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🎨 UI: UPDATE DIALOG
// =============================================================================
class UpdateDialog extends StatelessWidget {
  final String version;
  final String changelog;
  final String downloadUrl;
  final bool isForceUpdate;
  final VoidCallback onIgnored;

  const UpdateDialog({
    super.key,
    required this.version,
    required this.changelog,
    required this.downloadUrl,
    required this.isForceUpdate,
    required this.onIgnored,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !isForceUpdate,
      child: Dialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9D4EDD).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: const Color(0xFF9D4EDD),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Update Available",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Version $version",
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Container(
                constraints: BoxConstraints(maxHeight: 250.h),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildChangelogWidgets(changelog),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  if (!isForceUpdate)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          onIgnored();
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Ignore for now",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ),
                  if (!isForceUpdate) SizedBox(width: 12.w),
                  Expanded(
                    flex: isForceUpdate ? 1 : 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9D4EDD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      onPressed: () => url_launcher.launchUrl(
                        Uri.parse(downloadUrl),
                        mode: url_launcher.LaunchMode.externalApplication,
                      ),
                      child: Text(
                        "Download Update",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChangelogWidgets(String text) {
    List<Widget> widgets = [];
    List<String> lines = text.split('\n');
    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(SizedBox(height: 8.h));
        continue;
      }
      if (line.startsWith('##')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
            child: Text(
              line.replaceAll('##', '').trim(),
              style: TextStyle(
                color: const Color(0xFFE0AAFF),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      } else if (line.startsWith('-')) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: 4.h, left: 8.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "• ",
                  style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                ),
                Expanded(
                  child: Text(
                    line.substring(1).trim(),
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Text(
            line,
            style: TextStyle(color: Colors.grey, fontSize: 13.sp),
          ),
        );
      }
    }
    return widgets;
  }
}
