import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:otakunexa/Youtube/Playlist/models/youtube_playlist_model.dart';
import 'package:otakunexa/Youtube/Playlist/service/youtube_offline_playlist.dart';
import 'package:otakunexa/Youtube/Playlist/youtube_anime_details.dart';
import 'package:otakunexa/pages/Main/anime_about_page.dart';
import 'package:otakunexa/OuterShores/teleg/teleg_service.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';
import 'package:shimmer/shimmer.dart';

// Unified Search Result Model
class SearchResult {
  final SearchResultType type;
  final AnimeModel? anime;
  final YoutubePlaylist? youtubePlaylist;
  bool isAvailable;
  String language;

  SearchResult({
    required this.type,
    this.anime,
    this.youtubePlaylist,
    this.isAvailable = false,
    this.language = "🌍 Multi-Lang",
  });

  String get title {
    if (type == SearchResultType.anime && anime != null) {
      return anime!.data.titleEnglish.isNotEmpty
          ? anime!.data.titleEnglish
          : anime!.data.title;
    } else if (type == SearchResultType.youtube && youtubePlaylist != null) {
      return youtubePlaylist!.title;
    }
    return '';
  }

  String get imageUrl {
    if (type == SearchResultType.anime && anime != null) {
      final images = anime!.data.images.jpg;
      return images.largeImageUrl.isNotEmpty ? images.largeImageUrl : images.imageUrl;
    } else if (type == SearchResultType.youtube && youtubePlaylist != null) {
      return youtubePlaylist!.thumbnail;
    }
    return '';
  }
}

enum SearchResultType { anime, youtube }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  // State variables
  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounceTimer;
  String? _selectedCategory;
  
  // Pagination variables
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isFetchingMore = false;

  final List<String> _categories = [
    'Action', 'Adventure', 'Comedy', 'Drama', 'Ecchi', 'Fantasy', 'Hentai',
    'Horror', 'Mecha', 'Music', 'Mystery', 'Psychological', 'Romance',
    'Sci-Fi', 'Slice of Life', 'Sports', 'Supernatural', 'Thriller'
  ];

  // API URLs
  static const String _anilistUrl = 'https://graphql.anilist.co';
  static const String _jikanUrl = 'https://api.jikan.moe/v4/anime';

  @override
  void initState() {
    super.initState();
    SassyAiService.instance.activeSearchController = _searchController;
    SassyAiService.instance.activeSearchCallback = _onSearchChanged;
    
    _scrollController.addListener(_onScroll);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isFetchingMore && _hasNextPage) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    _performSearch(_searchController.text, isLoadMore: true);
  }

  @override
  void dispose() {
    SassyAiService.instance.activeSearchController = null;
    SassyAiService.instance.activeSearchCallback = null;
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 1. SEARCH LOGIC
  // ---------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isEmpty && _selectedCategory == null) {
        setState(() {
          _searchResults = [];
          _errorMessage = null;
          _isLoading = false;
        });
        return;
      }
      _performSearch(query);
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null; // Deselect
      } else {
        _selectedCategory = category;
      }
    });
    
    // Trigger search directly 
    _onSearchChanged(_searchController.text);
  }

  Future<void> _performSearch(String query, {bool isLoadMore = false}) async {
    if (isLoadMore) {
      setState(() {
        _isFetchingMore = true;
        _currentPage++;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasNextPage = true;
      });
    }

    List<SearchResult> combinedResults = [];

    // Search YouTube playlists from JSON
    try {
      final searchQuery = query.trim().isNotEmpty ? query : (_selectedCategory ?? '');
      if (searchQuery.isNotEmpty) {
        final youtubeResults = await PlaylistService.searchPlaylistsBatch(
          query: searchQuery,
          startIndex: (_currentPage - 1) * 10,
          batchSize: 10,
        );

        for (var playlist in youtubeResults) {
          combinedResults.add(
            SearchResult(
              type: SearchResultType.youtube,
              youtubePlaylist: playlist,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("YouTube search error: $e");
    }

    // Search AniList (Primary)
    List<AnimeModel> anilistResults = [];
    try {
      anilistResults = await _searchAniList(query, page: _currentPage);
    } catch (e) {
      debugPrint("AniList search error: $e");
    }

    // Fallback to Jikan if AniList fails
    if (anilistResults.isEmpty) {
      try {
        anilistResults = await _searchJikan(query, page: _currentPage);
      } catch (e) {
        debugPrint("Jikan search error: $e");
      }
    }

    // Add anime results
    for (var anime in anilistResults) {
      combinedResults.add(
        SearchResult(type: SearchResultType.anime, anime: anime),
      );
    }

    // --- FETCH AVAILABILITY FOR SORTING ---
    if (combinedResults.any((r) => r.type == SearchResultType.anime)) {
      List<Future<void>> availabilityFutures = [];
      for (var result in combinedResults) {
        if (result.type == SearchResultType.anime && result.anime != null) {
          availabilityFutures.add(() async {
            try {
              final res = await AnimeDownloadService.checkAvailability(result.anime!.data.malId.toString());
              if (res != null && res['data'] != null) {
                result.isAvailable = true;
                var rawData = res['data'];
                if (rawData['seasons'] != null) {
                  Map<String, dynamic> seasons = rawData['seasons'];
                  for (var seasonKey in seasons.keys) {
                    var seasonData = seasons[seasonKey];
                    if (seasonData['language'] != null) {
                      result.language = seasonData['language'].toString().replaceAll("/", " | ");
                      break;
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint("Availability check error: $e");
            }
          }());
        }
      }
      
      await Future.wait(availabilityFutures);
      
      // Sort combinedResults based on availability
      // Available items will be placed at the top while preserving anilist/youtube popularity order internally
      combinedResults.sort((a, b) {
        if (a.isAvailable && !b.isAvailable) return -1;
        if (!a.isAvailable && b.isAvailable) return 1;
        return 0; 
      });
    }

    if (!mounted) return;

    setState(() {
      if (isLoadMore) {
        _searchResults.addAll(combinedResults);
        _isFetchingMore = false;
      } else {
        _searchResults = combinedResults;
        _isLoading = false;
      }
      
      if (_searchResults.isEmpty) {
        _errorMessage = 'No results found';
        if (SassyAiService.instance.isGhostNavigating) {
          SassyAiService.instance.isGhostNavigating = false;
          SassyAiService.instance.handleGhostAutomationResult(false);
        }
      } else if (SassyAiService.instance.isGhostNavigating) {
        final firstItem = _searchResults.first;
        if (firstItem.type == SearchResultType.anime && firstItem.anime != null) {
          // DO NOT disable isGhostNavigating here. Let AnimeAboutPage handle it!
          SassyAiService.instance.handleGhostAutomationResult(firstItem.isAvailable);
          Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeAboutPage(selectedAnime: firstItem.anime!)));
        } else {
          SassyAiService.instance.isGhostNavigating = false;
          SassyAiService.instance.handleGhostAutomationResult(false);
        }
      }
    });
  }

  // AniList GraphQL Search
  Future<List<AnimeModel>> _searchAniList(String query, {int page = 1}) async {
    const String graphqlQuery = '''
      query (\$search: String, \$genre: String, \$isAdult: Boolean, \$sort: [MediaSort], \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo {
            hasNextPage
          }
          media(search: \$search, genre: \$genre, isAdult: \$isAdult, type: ANIME, sort: \$sort) {
            id
            idMal
            title {
              romaji
              english
              native
            }
            description(asHtml: false)
            coverImage {
              large
              medium
            }
            bannerImage
            status
            episodes
            duration
            format
            startDate {
              year
              month
              day
            }
            endDate {
              year
              month
              day
            }
            season
            seasonYear
            averageScore
            meanScore
            popularity
            favourites
            genres
            studios(isMain: true) {
              nodes {
                name
              }
            }
            nextAiringEpisode {
              timeUntilAiring
            }
          }
        }
      }
    ''';

    final response = await http
        .post(
          Uri.parse(_anilistUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'query': graphqlQuery,
            'variables': {
              if (query.trim().isNotEmpty) 'search': query,
              if (_selectedCategory != null) 'genre': _selectedCategory,
              if (_selectedCategory == 'Hentai') 'isAdult': true,
              'sort': query.trim().isNotEmpty ? ['SEARCH_MATCH', 'POPULARITY_DESC'] : ['POPULARITY_DESC'],
              'page': page,
              'perPage': 25,
            },
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['errors'] != null) {
        throw Exception('AniList API error: ${data['errors']}');
      }

      final pageInfo = data['data']?['Page']?['pageInfo'] ?? {};
      if (mounted) {
        setState(() {
          _hasNextPage = pageInfo['hasNextPage'] ?? false;
        });
      }

      final List<dynamic> mediaList = data['data']?['Page']?['media'] ?? [];
      return _convertAniListToAnimeModel(mediaList);
    } else {
      throw Exception('AniList API returned status ${response.statusCode}');
    }
  }

  // Convert AniList response to AnimeModel
  List<AnimeModel> _convertAniListToAnimeModel(List<dynamic> mediaList) {
    return mediaList.map((media) {
      final title = media['title'] ?? {};
      final coverImage = media['coverImage'] ?? {};

      // Convert AniList format to Jikan/MAL format
      final malId = media['idMal'] ?? media['id'] ?? 0;
      final isAiring =
          media['status'] == 'RELEASING' || media['nextAiringEpisode'] != null;

      final year = media['startDate']?['year'] ?? 0;
      final score = (media['averageScore'] ?? media['meanScore'] ?? 0) / 10.0;

      // Build image URLs
      final largeImage = coverImage['large'] ?? coverImage['medium'] ?? '';
      final imageUrl = largeImage.isNotEmpty ? largeImage : '';

      // Create AnimeData in Jikan format
      final animeData = AnimeData(
        malId: malId,
        url: 'https://anilist.co/anime/$malId',
        images: AnimeImages(
          jpg: AnimeImage(
            imageUrl: imageUrl,
            smallImageUrl: coverImage['medium'] ?? imageUrl,
            largeImageUrl: imageUrl,
          ),
          webp: AnimeImage(
            imageUrl: imageUrl,
            smallImageUrl: coverImage['medium'] ?? imageUrl,
            largeImageUrl: imageUrl,
          ),
        ),
        trailer: AnimeTrailer(images: AnimeTrailerImages()),
        approved: true,
        titles: [
          AnimeTitle(type: 'Default', title: title['romaji'] ?? ''),
          if (title['english'] != null)
            AnimeTitle(type: 'English', title: title['english']),
          if (title['native'] != null)
            AnimeTitle(type: 'Japanese', title: title['native']),
        ],
        title: title['romaji'] ?? title['english'] ?? '',
        titleEnglish: title['english'] ?? title['romaji'] ?? '',
        titleJapanese: title['native'] ?? '',
        titleSynonyms: [],
        type: media['format']?.toString().replaceAll('_', ' ') ?? 'TV',
        source: 'Unknown',
        episodes: media['episodes'],
        status: _convertStatus(media['status']),
        airing: isAiring,
        aired: AnimeAired(
          from: _parseDate(media['startDate']),
          to: _parseDate(media['endDate']),
          prop: AnimeAiredProp(
            from: AnimeAiredDate(
              year: media['startDate']?['year'],
              month: media['startDate']?['month'],
              day: media['startDate']?['day'],
            ),
            to: AnimeAiredDate(
              year: media['endDate']?['year'],
              month: media['endDate']?['month'],
              day: media['endDate']?['day'],
            ),
          ),
          string: year > 0 ? '$year' : '',
        ),
        duration: media['duration'] != null
            ? '${media['duration']} min'
            : 'Unknown',
        rating: 'PG-13',
        score: score,
        scoredBy: media['popularity'] ?? 0,
        rank: 0,
        popularity: media['popularity'] ?? 0,
        members: media['popularity'] ?? 0,
        favorites: media['favourites'] ?? 0,
        synopsis: media['description'] ?? '',
        background: '',
        season: media['season']?.toString().toUpperCase() ?? '',
        year: year,
        broadcast: AnimeBroadcast(day: '', time: '', timezone: '', string: ''),
        producers: [],
        licensors: [],
        studios:
            (media['studios']?['nodes'] as List<dynamic>?)
                ?.map(
                  (studio) => AnimeStudio(
                    malId: 0,
                    type: 'anime',
                    name: studio['name'] ?? '',
                    url: '',
                  ),
                )
                .toList() ??
            [],
        genres:
            (media['genres'] as List<dynamic>?)
                ?.map(
                  (genre) => AnimeGenre(
                    malId: 0,
                    type: 'anime',
                    name: genre.toString(),
                    url: '',
                  ),
                )
                .toList() ??
            [],
        explicitGenres: [],
        themes: [],
        demographics: [],
      );

      return AnimeModel(data: animeData);
    }).toList();
  }

  String _convertStatus(String? status) {
    switch (status) {
      case 'RELEASING':
        return 'Currently Airing';
      case 'FINISHED':
        return 'Finished Airing';
      case 'NOT_YET_RELEASED':
        return 'Not yet aired';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  DateTime? _parseDate(Map<String, dynamic>? date) {
    if (date == null) return null;
    try {
      final year = date['year'] ?? 0;
      final month = date['month'] ?? 1;
      final day = date['day'] ?? 1;
      if (year > 0) {
        return DateTime(year, month, day);
      }
    } catch (e) {
      debugPrint("Date parse error: $e");
    }
    return null;
  }

  // Jikan API Search (Fallback)
  Future<List<AnimeModel>> _searchJikan(String query, {int page = 1}) async {
    final Map<String, dynamic> params = {
      if (query.trim().isNotEmpty) 'q': query,
      'sfw': (_selectedCategory == 'Hentai' || _selectedCategory == 'Ecchi') ? 'false' : 'true',
      'limit': '25',
      'page': page.toString(),
    };

    if (_selectedCategory == 'Hentai') {
      params['genres'] = '12';
    } else if (_selectedCategory == 'Ecchi') {
      params['genres'] = '9';
    }
    
    if (query.trim().isEmpty) {
      params['order_by'] = 'popularity';
      params['sort'] = 'desc';
    }

    final Uri url = Uri.parse(_jikanUrl).replace(
      queryParameters: params,
    );

    final response = await http.get(url).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final pagination = data['pagination'] ?? {};
      
      if (mounted) {
        setState(() {
          _hasNextPage = pagination['has_next_page'] ?? false;
        });
      }

      final List<dynamic> rawList = data['data'] ?? [];

      return rawList.map((jsonItem) {
        final animeData = AnimeData.fromJson(jsonItem);
        return AnimeModel(data: animeData);
      }).toList();
    } else {
      throw Exception('Jikan API returned status ${response.statusCode}');
    }
  }

  // ---------------------------------------------------------------------------
  // 2. UI BUILDERS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Ambient Glow
          Positioned(
            top: 100.h,
            left: -100.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withOpacity(0.12),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildCategoryChips(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          
          return Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: () => _onCategorySelected(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCirc,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            const Color(0xFFB388FF),
                            const Color(0xFF7C4DFF)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [
                            const Color(0xFF1E1E1E),
                            const Color(0xFF2C2C2C),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(25.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.6),
                            blurRadius: 12.r,
                            spreadRadius: 2.r,
                            offset: Offset(0, 4.h),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4.r,
                            offset: Offset(0, 2.h),
                          )
                        ],
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : Colors.white.withOpacity(0.08),
                    width: 1.w,
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                      ],
                      Text(
                        category,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 14.sp,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            color: const Color(0xFF0F0F0F).withOpacity(0.7),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.05),
                  width: 1.h,
                )
              )
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18.sp,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Discover',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D4EDD).withOpacity(0.15),
            blurRadius: 15.r,
            offset: Offset(0, 4.h),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.w),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: _onSearchChanged,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            cursorColor: const Color(0xFF9D4EDD),
            decoration: InputDecoration(
              hintText: 'Search anime (e.g. "One Piece")',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14.sp,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: const Color(0xFF9D4EDD).withOpacity(0.8),
                size: 24.sp,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: Colors.white54,
                        size: 20.sp,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,
                vertical: 16.h,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_errorMessage != null && _searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64.sp,
              color: Colors.redAccent.withOpacity(0.7),
            ),
            SizedBox(height: 16.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty && (_searchController.text.isNotEmpty || _selectedCategory != null)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.sp,
              color: Colors.white.withOpacity(0.1),
            ),
            SizedBox(height: 16.h),
            Text(
              'No results found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_filter_rounded,
              size: 80.sp,
              color: Colors.white.withOpacity(0.05),
            ),
            SizedBox(height: 16.h),
            Text(
              'Type to explore or select a category...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.w,
              mainAxisSpacing: 20.h,
              childAspectRatio: 0.7,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              if (result.type == SearchResultType.youtube) {
                return _buildYouTubeCard(result);
              } else {
                return _buildAnimeCard(result);
              }
            },
          ),
        ),
        if (_isFetchingMore)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.w,
                color: const Color(0xFF9D4EDD),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimeCard(SearchResult result) {
    if (result.anime == null) return const SizedBox();
    final anime = result.anime!;
    final bool isAiring = anime.data.airing;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeAboutPage(selectedAnime: anime),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: result.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: const Color(0xFF9D4EDD),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.95),
                            ],
                            stops: const [0.5, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                    if (anime.data.score > 0)
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.6),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                anime.data.score.toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (result.isAvailable)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            result.language,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    if (isAiring)
                      Positioned(
                        bottom: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.4),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                          child: Text(
                            'AIRING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${anime.data.year > 0 ? anime.data.year : "N/A"} • ${anime.data.type}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.sp,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: result.isAvailable
                          ? const Color(0xFF00E676).withOpacity(0.2)
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: result.isAvailable ? const Color(0xFF00E676) : Colors.grey[700]!,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      result.isAvailable ? "AVAILABLE" : "UNAVAILABLE",
                      style: TextStyle(
                        color: result.isAvailable ? const Color(0xFF00E676) : Colors.grey[500],
                        fontSize: 8.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYouTubeCard(SearchResult result) {
    if (result.youtubePlaylist == null) return const SizedBox();
    final playlist = result.youtubePlaylist!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                YouTubeAnimeDetails(anime: playlist, playlistId: playlist.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12.r,
                    offset: Offset(0, 6.h),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.w,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: result.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: const Color(0xFF9D4EDD),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white30,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.2),
                              Colors.black.withOpacity(0.95),
                            ],
                            stops: const [0.5, 0.75, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // YouTube Badge
                    Positioned(
                      top: 8.h,
                      right: 8.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Colors.white,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'YOUTUBE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Episode Count Badge
                    if (playlist.itemCount > 0)
                      Positioned(
                        top: 8.h,
                        left: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            '${playlist.itemCount} Eps',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'YouTube Playlist • ${playlist.itemCount} Episodes',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 20.h,
        childAspectRatio: 0.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1E1E1E),
          highlightColor: const Color(0xFF2C2C2C),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                height: 14.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                height: 12.h,
                width: 80.w,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
