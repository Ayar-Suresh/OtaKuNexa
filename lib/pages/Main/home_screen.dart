import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/OuterShores/metadata/anime_horizontal_section.dart';
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:otakunexa/OuterShores/service/categ_manager.dart';
import 'package:otakunexa/OuterShores/teleg/teleg_service.dart';
import 'package:otakunexa/Youtube/Playlist/models/youtube_playlist_model.dart';
import 'package:otakunexa/Youtube/Playlist/service/youtube_offline_playlist.dart';
import 'package:otakunexa/Youtube/Playlist/youtube_anime_details.dart';
import 'package:otakunexa/youtube/Episodes/service/playlist_json_service_ep.dart';
import 'package:otakunexa/Youtube/Recommendations/play_recommendation.dart';
import 'package:otakunexa/Youtube/Recommendations/recommendation_repository.dart';
import 'package:otakunexa/pages/Main/search_screen.dart';
import 'package:otakunexa/widgets/categorytab_widget.dart';
import 'package:otakunexa/widgets/drawer_widget.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final CategoryManager _categoryManager = CategoryManager();

  List<YoutubePlaylist> _allPlaylists = [];
  final int _batchSize = 20;
  List<YoutubePlaylist> _displayedPlaylists = [];

  bool _isLoadingMore = false;
  bool _isLoadingPlaylists = true;
  bool _isCategoriesLoading = true;
  final VideoController _videoController = VideoController();
  bool _isLoadingVideos = true;
  late ScrollController _scrollController;

  bool _isForbidden = true;
  bool _isYTVisible = true;
  bool _isRecVisible = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _setupScrollListener();
    _initializeAppServices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnimeDownloadService.checkForUpdate(context);
    });
  }

  Future<void> _initializeAppServices() async {
    // Load json data first so we can filter immediately
    await PlaylistJsonService().loadPlaylistData();
    _loadPlaylists();
    _loadCategories();
    _loadVideos();
  }

  Future<void> _refreshAndRandomize() async {
    await PlaylistService.reshufflePlaylists();
    await _loadPlaylists();
  }

  Future<void> _loadVideos() async {
    await _videoController.initialize();
    if (!mounted) return;
    setState(() => _isLoadingVideos = false);
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200.h &&
          !_isLoadingMore &&
          _displayedPlaylists.length < _allPlaylists.length) {
        _loadMorePlaylists();
      }
    });
  }

  // --- 🔥 NEW: Handle Global Server Switch from Home ---
  Future<void> _handleGlobalServerSwitch() async {
    bool refreshed = await AnimeDownloadService.openManualServerDialog(context);
    if (refreshed) {
      // 1. Wipe RAM Cache in CategoryManager
      _categoryManager.hardReset();
      // 2. Reload everything
      if (!mounted) return;
      setState(() {
        _isCategoriesLoading = true;
      });
      await _loadCategories();
    }
  }

  Future<void> _loadCategories() async {
    if (!mounted) return;
    setState(() {
      _isCategoriesLoading = true;
    });

    await _categoryManager.loadAllCategories();
    if (!mounted) return;

    setState(() {
      _isCategoriesLoading = false;
    });
  }

  Future<void> _loadPlaylists() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPlaylists = true;
    });

    try {
      final totalCount = await PlaylistService.getTotalCount();
      final firstBatch = await PlaylistService.getPlaylistsBatch(
        startIndex: 0,
        batchSize: _batchSize,
      );

      if (!mounted) return;

      _displayedPlaylists = firstBatch;
      _allPlaylists = List.generate(
        totalCount,
        (index) => YoutubePlaylist(
          id: '',
          title: '',
          channelId: '',
          thumbnail: '',
          itemCount: 0,
        ),
      );

      setState(() {
        _isLoadingPlaylists = false;
      });
    } catch (e) {
      print('Error loading playlists: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPlaylists = false;
      });
    }
  }

  void _loadMorePlaylists() async {
    if (_isLoadingMore || _displayedPlaylists.length >= _allPlaylists.length) {
      return;
    }

    if (!mounted) return;
    
    // Defer the state update to avoid "setState() called during build" 
    // when the keyboard resizes the viewport and triggers a layout pass.
    Future.microtask(() {
      if (mounted) setState(() => _isLoadingMore = true);
    });

    try {
      int nextIndex = _displayedPlaylists.length;
      final newBatch = await PlaylistService.getPlaylistsBatch(
        startIndex: nextIndex,
        batchSize: _batchSize,
      );

      if (mounted && newBatch.isNotEmpty) {
        setState(() {
          _displayedPlaylists.addAll(newBatch);
          _isLoadingMore = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      }
    } catch (e) {
      print('Error loading more playlists: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  // =============== UI BUILDERS ===============

  Widget _buildLoadingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: SizedBox(
          height: 24.w,
          width: 24.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            color: Color(0xFF9D4EDD),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      backgroundColor: const Color(0xFF1A1A1A),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: Colors.white, size: 24.sp),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(children: [Image.asset('assets/logo/logo.png', width: 80.w)]),
      actions: [
        Container(
          margin: EdgeInsets.symmetric(vertical: 10.h),
          padding: EdgeInsets.only(right: 8.0.w),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFE5F1),
                        const Color(0xFFF0E6FF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9D4EDD).withOpacity(0.25),
                        blurRadius: 15.r,
                        offset: Offset(0, 5.h),
                      ),
                    ],
                  ),
                  height: 48.h,
                  width: 190.w,
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 15.w),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome_outlined,
                                size: 18.sp,
                                color: const Color(0xFF9D4EDD).withOpacity(0.7),
                              ),
                              SizedBox(width: 8.w),
                              AnimatedRecommendation(
                                recommendations: [
                                  'Naruto',
                                  'One Piece',
                                  'Bleach',
                                  'Attack on Titan',
                                  'Demon Slayer',
                                  'My Hero Academia',
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.all(4.w),
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9D4EDD),
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9D4EDD).withOpacity(0.4),
                              blurRadius: 8.r,
                              offset: Offset(0, 2.h),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedSection() {
    if (_isLoadingVideos) {
      return SizedBox(
        height: 230.h,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final videos = _videoController.displayedVideos;

    if (videos.isEmpty) {
      return const Center(
        child: Text(
          "No recommendations available",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Anime Spotlight',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 230.h,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: videos.length,
            onPageChanged: (index) async {
              if (index >= videos.length - 3) {
                await _videoController.loadMore();
                if (!mounted) return;
                setState(() {});
              }
            },
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () {
                  final vid = videos[index];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => YoutubePlayerScreen(videos: vid),
                    ),
                  );
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF7B2CBF).withOpacity(0.3),
                        const Color(0xFF9D4EDD).withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: CachedNetworkImage(
                          imageUrl: video.thumbnail,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Icon(
                            Icons.broken_image,
                            color: Colors.white30,
                            size: 60.sp,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16.r),
                              bottomRight: Radius.circular(16.r),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  video.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  "Likes: ${video.likes} • ${video.vidDuration}s",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnimeGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 350),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _isYTVisible ? 'Watch Now' : 'Zero Distraction',
                  key: ValueKey(_isYTVisible),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5.h),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.dns, size: 10.sp, color: Colors.deepPurple),
                    SizedBox(width: 4.w),
                    Text(
                      AnimeDownloadService.currentServerName.replaceAll(
                        "Server ",
                        "",
                      ), // Shorten text
                      style: TextStyle(color: Colors.white70, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
              _buildYTToggleButton(),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        if (_isLoadingPlaylists) _buildListShimmer(),
        if (!_isLoadingPlaylists) _buildContentList(),
      ],
    );
  }

  Widget _buildYTToggleButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isYTVisible = !_isYTVisible;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: _isYTVisible
              ? const Color(0xFF9D4EDD).withOpacity(0.15)
              : const Color(0xFF2A2A2A).withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _isYTVisible ? const Color(0xFF9D4EDD) : Colors.transparent,
            width: 1.w,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isYTVisible ? Icons.visibility : Icons.visibility_off,
              color: _isYTVisible ? const Color(0xFF9D4EDD) : Colors.white60,
              size: 16.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              _isYTVisible ? 'Hide YT' : 'Show YT',
              style: TextStyle(
                color: _isYTVisible ? const Color(0xFF9D4EDD) : Colors.white60,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 🛠️ FIXED: Content List Builder (Correct Logic)
  // ===========================================================================
  Widget _buildContentList() {
    if (!_isYTVisible) {
      return _buildCategoriesOnly();
    }
    return _buildMixedContent();
  }

  Widget _buildCategoriesOnly() {
    final displayCategories = _categoryManager.getCategoriesForDisplay();
    return Column(
      children: displayCategories.map((category) {
        return Column(
          children: [
            _buildSmartCategoryItem(category),
            SizedBox(height: 16.h),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMixedContent() {
    if (!_isForbidden) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _displayedPlaylists.length,
        itemBuilder: (context, index) {
          return _buildPlaylistItem(_displayedPlaylists[index]);
        },
      );
    }

    int totalItems =
        _displayedPlaylists.length + _categoryManager.categories.length;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // 1. Check if this index belongs to a Category
        final category = _categoryManager.getCategoryAtPosition(index);

        if (category != null) {
          return _buildSmartCategoryItem(category);
        }

        // 2. Calculate Playlist Index
        final categoriesBefore = _categoryManager.categories
            .where((cat) => cat.insertAtIndex < index)
            .length;
        final playlistIndex = index - categoriesBefore;

        if (playlistIndex >= _displayedPlaylists.length || playlistIndex < 0) {
          return const SizedBox();
        }

        final anime = _displayedPlaylists[playlistIndex];
        return _buildPlaylistItem(anime);
      },
    );
  }

  // 🧠 SMART BUILDER: Decides between Loading, Content, or Error
  Widget _buildSmartCategoryItem(CategoryConfig category) {
    final bool isLoading = _categoryManager.isLoading(category.id);
    final List<AnimeData>? data = _categoryManager.getAnimeData(category.id);

    // 1. SPECIAL CASE: "New Arrivals" (The GitHub Category)
    if (category.id == 'recent_added_category') {
      // If Data is missing OR it is still loading -> Show the Hunting UI
      if (data == null || data.isEmpty || isLoading) {
        // 🔥 This shows the special "Hunting" widget that eventually shows the button
        return _ServerHuntingWidget(onManualSwitch: _handleGlobalServerSwitch);
      }
      // If Data found -> Widget vanishes, Content shows below
    } else {
      // For Normal Offline Categories: If empty, hide them.
      if (!isLoading && (data == null || data.isEmpty)) {
        return const SizedBox();
      }
    }

    // 2. SUCCESS (or standard loading for offline cats): Show Content
    return _buildCategorySection(category);
  }

  Widget _buildCategorySection(CategoryConfig category) {
    final animeData = _categoryManager.getAnimeData(category.id);
    // Logic: If Manager says specific cat is loading OR global loading is on
    final isLoading =
        _categoryManager.isLoading(category.id) || _isCategoriesLoading;

    return AnimeHorizontalSection(
      title: category.title,
      animeList:
          animeData?.map((data) => AnimeModel(data: data)).toList() ?? [],
      isLoading: isLoading,
    );
  }

  Widget _buildPlaylistItem(YoutubePlaylist anime) {
    // 🔥 FILTER OUT RESTRICTED / EMPTY PLAYLISTS (API empty or JSON empty)
    if (anime.itemCount == 0) return const SizedBox.shrink();
    final localItems = PlaylistJsonService().getPlaylistItems(anime.id);
    if (localItems == null || localItems.isEmpty) return const SizedBox.shrink();

    final playlistId = anime.id;
    final parsed = parseLanguageAndType(anime.title);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.r),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.3),
            const Color(0xFF2A2A2A).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: const Color(0xFF9D4EDD).withOpacity(0.1),
          width: 0.5.w,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 150.w,
              height: 105.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8.r,
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Stack(
                  children: [
                    Container(
                      width: 150.w,
                      height: 105.h,
                      color: const Color(0xFF2A2A2A),
                    ),
                    CachedNetworkImage(
                      imageUrl: anime.thumbnail,
                      width: 150.w,
                      height: 105.h,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => Container(
                        width: 150.w,
                        height: 105.h,
                        color: const Color(0xFF2A2A2A),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF9D4EDD),
                            strokeWidth: 2.w,
                          ),
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        width: 150.w,
                        height: 105.h,
                        color: const Color(0xFF2A2A2A),
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.white30,
                          size: 30.sp,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 40.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SizedBox(
                height: 115.h,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9D4EDD).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: const Color(0xFF9D4EDD).withOpacity(0.4),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.movie_filter_outlined,
                                color: Color(0xFFB97FE5),
                                size: 14.sp,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                '${parsed["language"]}/',
                                style: TextStyle(
                                  color: Color(0xFFB97FE5),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                parsed["type"]!,
                                style: TextStyle(
                                  color: Color(0xFFB97FE5),
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A).withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_circle_outline,
                                color: Colors.white70,
                                size: 14.sp,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                "${anime.itemCount} EP",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => YouTubeAnimeDetails(
                                  anime: anime,
                                  playlistId: playlistId,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9D4EDD),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 14.sp,
                                ),
                                SizedBox(width: 7.w),
                                Text(
                                  'Play',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListShimmer() {
    return Column(
      children: List.generate(5, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A1A).withOpacity(0.3),
                const Color(0xFF2A2A2A).withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFF9D4EDD).withOpacity(0.1),
              width: 0.5.w,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade800,
              highlightColor: Colors.grey.shade700,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 90.w,
                    height: 130.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: SizedBox(
                      height: 130.h,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 16.h,
                                width: double.infinity,
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(height: 8.h),
                              Container(
                                height: 14.h,
                                width: 180.w,
                                color: Colors.grey.shade700,
                              ),
                              SizedBox(height: 12.h),
                              Container(
                                height: 24.h,
                                width: 100.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 24.h,
                                width: 60.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              Container(
                                height: 24.h,
                                width: 24.w,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade700,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: _buildAppBar(),
      drawer: const CustomDrawer(selectedPage: "Home"),
      body: Column(
        children: [
          SmartSlidingTabs(
            initialIndex: 0,
            onChanged: (int value) {
              if (value == 0) {
                _refreshAndRandomize();
                setState(() {
                  _isForbidden = true;
                  _isRecVisible = true;
                  _isYTVisible = true;
                });
              } else if (value == 1) {
                _loadVideos();
                setState(() {});
              } else if (value == 2) {
                setState(() {
                  _isForbidden = false;
                  _isRecVisible = true;
                  _isYTVisible = true;
                });
              } else if (value == 3) {
                setState(() {
                  _isYTVisible = false;
                  _isRecVisible = false;
                });
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isRecVisible ? _buildFeaturedSection() : SizedBox(),
                  SizedBox(height: 24.h),
                  _buildAnimeGrid(),
                  if (_isLoadingMore) _buildLoadingIndicator(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedRecommendation extends StatefulWidget {
  const AnimatedRecommendation({super.key, required this.recommendations});

  final List<String> recommendations;

  @override
  State<AnimatedRecommendation> createState() => _AnimatedRecommendationState();
}

class _AnimatedRecommendationState extends State<AnimatedRecommendation> {
  int _charIndex = 0;
  int _currentIndex = 0;
  late Timer _cursorTimer;
  String _displayedText = '';
  bool _isTyping = true;
  bool _showCursor = true;
  late Timer _typingTimer;

  @override
  void dispose() {
    _typingTimer.cancel();
    _cursorTimer.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
    _startCursorBlinking();
  }

  void _startTypingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isTyping) {
        final fullText = widget.recommendations[_currentIndex];
        final runes = fullText.runes.toList();
        if (_charIndex < runes.length) {
          _charIndex++;
          _displayedText = String.fromCharCodes(runes.sublist(0, _charIndex));
          setState(() {});
        } else {
          _isTyping = false;
          _typingTimer.cancel();
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            _startDeletingAnimation();
          });
        }
      }
    });
  }

  void _startDeletingAnimation() {
    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final fullText = widget.recommendations[_currentIndex];
      final runes = fullText.runes.toList();

      if (_charIndex > 0) {
        _charIndex--;
        _displayedText = String.fromCharCodes(runes.sublist(0, _charIndex));
        setState(() {});
      } else {
        _typingTimer.cancel();
        _currentIndex = (_currentIndex + 1) % widget.recommendations.length;
        _isTyping = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          _startTypingAnimation();
        });
      }
    });
  }

  void _startCursorBlinking() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        _displayedText + (_showCursor ? '|' : ''),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Color(0xFF4A0E4E),
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Map<String, String> parseLanguageAndType(String title) {
  final lowerTitle = title.toLowerCase();

  String language = "Unknown";
  String type = "Version";

  if (lowerTitle.contains("english")) {
    language = "English";
  } else if (lowerTitle.contains("hindi"))
    language = "Hindi";
  else if (lowerTitle.contains("japanese"))
    language = "Japanese";
  else if (lowerTitle.contains("dual audio"))
    language = "Dual Audio";
  else if (lowerTitle.contains("multi audio"))
    language = "Multi Audio";

  if (lowerTitle.contains("dub")) {
    type = "Dub";
  } else if (lowerTitle.contains("sub"))
    type = "Sub";

  if (language == "Unknown" && type == "Version") {
    language = "Language";
    type = "Info";
  }

  return {"language": language, "type": type};
}

// =============================================================================
// 🆕 NEW COMPONENT: SERVER HUNTING INDICATOR (Replaces Error Widget)
// =============================================================================
class _ServerHuntingWidget extends StatefulWidget {
  final VoidCallback onManualSwitch;
  const _ServerHuntingWidget({required this.onManualSwitch});

  @override
  State<_ServerHuntingWidget> createState() => _ServerHuntingWidgetState();
}

class _ServerHuntingWidgetState extends State<_ServerHuntingWidget> {
  bool _showManualOption = false;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // ⏳ Timer: After 5 seconds of hunting, show the Manual Option
    _timer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showManualOption = true);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _showManualOption
              ? Colors.redAccent.withOpacity(0.3)
              : Colors.deepPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Status Row
          Row(
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _showManualOption
                      ? Colors.redAccent
                      : Colors.deepPurple,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                _showManualOption
                    ? "Connection Taking Longer..."
                    : "Connecting to Cloud Server...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // 2. Manual Option (Appears after 5 seconds)
          if (_showManualOption) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "You can enter a Server ID manually if auto-connection fails.",
                    style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "💡 Tip: Search Google for 'OtakuNexa Server ID Status' to find active codes.",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11.sp,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onManualSwitch,
                      icon: Icon(Icons.dns, size: 18.sp, color: Colors.white),
                      label: Text("Enter Server ID Manually"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
