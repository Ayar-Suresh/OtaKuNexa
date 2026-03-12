import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:otakunexa/OuterShores/service/categ_repository.dart';

class CategoryConfig {
  final String id;
  final String title;
  final String jsonFileName;
  final int insertAtIndex;

  CategoryConfig({
    required this.id,
    required this.title,
    required this.jsonFileName,
    required this.insertAtIndex,
  });
}

class CategoryManager {
  // Singleton Pattern
  static final CategoryManager _instance = CategoryManager._internal();
  factory CategoryManager() => _instance;
  CategoryManager._internal();

  final AnimeRepository _repository = AnimeRepository();

  final List<CategoryConfig> _categories = [
    // 🆕 GITHUB ONLINE CATEGORY (Index 1)
    CategoryConfig(
      id: 'recent_added_category',
      title: '✨ New Arrivals',
      jsonFileName: 'recent_added_category',
      insertAtIndex: 1,
    ),
    // 👇 OFFLINE CATEGORIES
    CategoryConfig(
      id: 'trending_anime_in_india',
      title: '🔥 Trending Anime In India',
      jsonFileName: 'trending_anime_in_india',
      insertAtIndex: 2,
    ),
    CategoryConfig(
      id: 'popular_hindi_dubbed',
      title: '🇮🇳 Popular Hindi Dubbed',
      jsonFileName: 'popular_hindi_dubbed',
      insertAtIndex: 35,
    ),
    CategoryConfig(
      id: 'popular_english_dubbed',
      title: '🇺🇸 Popular English Dubbed',
      jsonFileName: 'popular_english_dubbed',
      insertAtIndex: 9,
    ),
    CategoryConfig(
      id: 'otakunexa_top_picks',
      title: '🏆 OtakuNexa Top Picks',
      jsonFileName: 'otakunexa_top_picks',
      insertAtIndex: 14,
    ),
    CategoryConfig(
      id: 'you_may_also_like',
      title: '❤️ You May Also Like',
      jsonFileName: 'you_may_also_like',
      insertAtIndex: 15,
    ),
    CategoryConfig(
      id: 'top_picks_for_you',
      title: '✨ Top Picks 4U',
      jsonFileName: 'top_picks_for_you',
      insertAtIndex: 20,
    ),
    CategoryConfig(
      id: 'popular_in_india',
      title: '🌟 Popular In India',
      jsonFileName: 'popular_in_india',
      insertAtIndex: 24,
    ),
    CategoryConfig(
      id: 'hidden_gems',
      title: '💎 Hidden Gems',
      jsonFileName: 'hidden_gems',
      insertAtIndex: 25,
    ),
    CategoryConfig(
      id: 'fantasy_anime',
      title: '🐉 Fantasy Anime',
      jsonFileName: 'fantasy_anime',
      insertAtIndex: 29,
    ),
    CategoryConfig(
      id: 'evergreen_anime',
      title: '🌳 Evergreen Anime',
      jsonFileName: 'evergreen_anime',
      insertAtIndex: 30,
    ),
    CategoryConfig(
      id: 'anime_from_yt_recommend',
      title: '📺 YT Recommended',
      jsonFileName: 'anime_from_yt_recommend',
      insertAtIndex: 34,
    ),
  ];

  // In-Memory Cache
  final Map<String, List<AnimeData>> _cache = {};
  final Map<String, bool> _loadingStates = {};

  List<CategoryConfig> get categories => List.from(_categories);

  List<CategoryConfig> getCategoriesForDisplay() {
    return _categories
      ..sort((a, b) => a.insertAtIndex.compareTo(b.insertAtIndex));
  }

  CategoryConfig? getCategoryAtPosition(int position) {
    for (var category in _categories) {
      if (position == category.insertAtIndex) {
        return category;
      }
    }
    return null;
  }

  Future<void> loadAllCategories() async {
    for (var category in _categories) {
      // If already loaded, skip (unless cleared)
      if (_cache.containsKey(category.id) && _cache[category.id]!.isNotEmpty) {
        continue;
      }
      await _loadCategory(category);
    }
  }

  Future<void> _loadCategory(CategoryConfig category) async {
    _loadingStates[category.id] = true;

    try {
      final data = await _repository.getAnimeByCategory(category.jsonFileName);
      _cache[category.id] = data;
    } catch (e) {
      print('Error loading ${category.title}: $e');
      _cache[category.id] = [];
    }

    _loadingStates[category.id] = false;
  }

  List<AnimeData>? getAnimeData(String categoryId) {
    return _cache[categoryId];
  }

  // ✅ Returns TRUE by default to prevent premature error showing
  bool isLoading(String categoryId) {
    return _loadingStates[categoryId] ?? true;
  }

  // 🧹 NEW: Completely wipes memory to force a refresh from new Server
  void hardReset() {
    _cache.clear();
    _loadingStates.clear();
    print("🧹 CategoryManager: RAM Cache Cleared.");
  }
}
