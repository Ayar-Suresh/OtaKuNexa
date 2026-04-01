import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/Youtube/Playlist/models/youtube_playlist_model.dart';
import 'package:otakunexa/pages/Main/search_screen.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:otakunexa/youtube/Episodes/model/playlist_item.dart';
import 'package:otakunexa/youtube/Episodes/service/playlist_json_service_ep.dart';
import 'package:otakunexa/youtube/player/youtube_player_screen.dart';

class YouTubeAnimeDetails extends StatefulWidget {
  final YoutubePlaylist anime;
  final String playlistId;
  const YouTubeAnimeDetails({
    super.key,
    required this.anime,
    required this.playlistId,
  });

  @override
  State<YouTubeAnimeDetails> createState() => _AnimeDetailsState();
}

class _AnimeDetailsState extends State<YouTubeAnimeDetails> {
  final ScrollController _scrollController = ScrollController();
  final PlaylistJsonService _jsonService = PlaylistJsonService();

  List<PlaylistItem> _playlistItems = [];
  bool _isLoading = true;
  bool _isDescriptionExpanded = false;
  String _errorMessage = '';

  int extractEpisodeNumberForSorting(String title) {
    final lower = title.toLowerCase();

    final episodeRegex = RegExp(r'(episode|ep|e)[\s:\-]*([0-9]+)');
    final match = episodeRegex.firstMatch(lower);
    if (match != null) {
      return int.tryParse(match.group(2)!) ?? 9999;
    }

    final numRegex = RegExp(r'([0-9]+)');
    final numMatch = numRegex.firstMatch(lower);
    if (numMatch != null) {
      return int.tryParse(numMatch.group(1)!) ?? 9999;
    }

    return 9999;
  }

  @override
  void initState() {
    super.initState();
    _loadPlaylistData();
  }

  Future<void> _loadPlaylistData() async {
    try {
      // Load all playlist data from JSON
      await _jsonService.loadPlaylistData();

      // Get specific playlist items
      final items = _jsonService.getPlaylistItems(widget.playlistId);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (items != null) {
            _playlistItems = items;
            // 🔥 Sort after data actually loaded
            _playlistItems.sort((a, b) {
              final epA = extractEpisodeNumberForSorting(a.title);
              final epB = extractEpisodeNumberForSorting(b.title);
              return epA.compareTo(epB);
            });
          } else {
            _errorMessage = 'No episodes found for this playlist';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load episodes';
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToPlayer(PlaylistItem playlistItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => YoutubePlayerScreen(
          currentVideo: playlistItem,
          playlistItems: _playlistItems,
          playlistThumbnail: widget.anime.thumbnail,
        ),
      ),
    );
  }

  void _playFirstEpisode() {
    if (_playlistItems.isNotEmpty) {
      _navigateToPlayer(_playlistItems.first);
    }
  }

  // Helper to build visual star rating (from code 2)
  Widget _buildStarRating(double rating) {
    // Convert 10-point scale to 5-point scale
    double starCount = rating / 2;
    return Row(
      children: List.generate(5, (index) {
        if (index < starCount.floor()) {
          return Icon(Icons.star, color: Colors.deepPurple, size: 20.sp);
        } else if (index < starCount && starCount % 1 != 0) {
          return Icon(Icons.star_half, color: Colors.deepPurple, size: 20.sp);
        } else {
          return Icon(Icons.star_border, color: Colors.grey[700], size: 20.sp);
        }
      }),
    );
  }

  // Action Button Widget (from code 2)
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 26.sp),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  // Detail Card (from code 2)
  Widget _buildDetailCard(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.4),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(7.sp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: Colors.white.withOpacity(0.07),
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[400], fontSize: 11.sp),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      // Sticky bottom button (from code 2)
      bottomNavigationBar: _playlistItems.isNotEmpty
          ? ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20.w,
                    20.h,
                    20.w,
                    MediaQuery.of(context).padding.bottom + 20.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 1.h)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9D4EDD).withOpacity(0.05),
                        offset: const Offset(0, -10),
                        blurRadius: 20,
                      ),
                    ],
                  ),
              child: ElevatedButton(
                onPressed: _playFirstEpisode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_filled,
                      size: 24.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Start Watching E1',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header with fade effect (from code 2)
          SliverAppBar(
            expandedHeight: 500.h,
            floating: false,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
                child: Container(
                  height: 40,
                  width: 150,
                  padding: const EdgeInsets.all(2),
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.sp),
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Search Anime",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],

            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: widget.anime.thumbnail,
                    fit: BoxFit.fill,
                    fadeInDuration: Duration.zero,
                    errorWidget: (context, url, error) =>
                        Container(color: Colors.grey[900]),
                  ),
                  // Gradient overlay (from code 2)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.95),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.4, 0.7, 0.9, 1.0],
                      ),
                    ),
                  ),
                  // Title and info inside image area (from code 2)
                  Positioned(
                    bottom: 20.h,
                    left: 20.w,
                    right: 20.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            '🔥 YOUTUBE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          widget.anime.title,
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        // Star rating (from code 2) - using a sample rating
                        _buildStarRating(6.8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // Metadata section (modified from code 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 3.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            'HD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          '${_playlistItems.length} Episodes',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Icon(
                          Icons.access_time,
                          color: Colors.grey,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '~24m', // Sample duration
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    // Genres/Tags
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children:
                          [
                            'Action',
                            'Drama',
                            'Fantasy',
                            'Adventure',
                            'comedy',
                          ].map<Widget>((genre) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 6.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                genre,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              // Action buttons (from code 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.add, 'My List', () {
                      // Add to list functionality
                    }),
                    _buildActionButton(Icons.share, 'Share', () {
                      ShareService.shareAppApk(
                        type: ShareType.anime,
                        animeTitle: widget
                            .anime
                            .title, // Replace with your variable name
                        context: context,
                      );
                    }),
                  ],
                ),
              ),

              Divider(color: Colors.white10, height: 32.h),

              // Description with animated line (from code 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT CYBER STRIP
                    Stack(
                      children: [
                        Container(
                          width: 4.w,
                          height: _isDescriptionExpanded ? 120.h : 70.h,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        // FUTURISTIC MOVING LINE
                        Positioned.fill(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 700),
                            alignment: _isDescriptionExpanded
                                ? Alignment.bottomCenter
                                : Alignment.topCenter,
                            curve: Curves.easeInOut,
                            child: Container(
                              width: 4.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 14.w),
                    // TEXT + BUTTON
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 250),
                            crossFadeState: _isDescriptionExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            firstChild: Text(
                              '• Dive into a beautifully crafted world filled with rich lore and breathtaking visuals.\n'
                              '• Experience high-impact battles brought to life with stunning animation.\n'
                              '• Follow unforgettable characters on an emotional journey of growth and discovery.\n',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[300],
                                height: 1.5,
                              ),
                            ),
                            secondChild: Text(
                              '• Enjoy a perfect blend of action, drama, mystery, and heart-touching moments.\n'
                              '• Every episode delivers cinematic scenes, powerful storytelling, and immersive sound design.',
                              style: TextStyle(
                                color: Colors.grey[300],
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          GestureDetector(
                            onTap: () => setState(
                              () => _isDescriptionExpanded =
                                  !_isDescriptionExpanded,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isDescriptionExpanded
                                      ? "Show Less"
                                      : "Read More",
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  _isDescriptionExpanded
                                      ? Icons.remove_circle_outline
                                      : Icons.add_circle_outline,
                                  size: 18,
                                  color: Colors.deepPurple,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Professional Details Grid (from code 2)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anime Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 2.2,
                      mainAxisSpacing: 12.h,
                      crossAxisSpacing: 12.w,
                      children: [
                        _buildDetailCard(Icons.business, 'Studio', 'Youtube'),
                        _buildDetailCard(Icons.tv, 'Type', 'Sub & Dub'),
                        _buildDetailCard(
                          Icons.calendar_today,
                          'Status',
                          'Ongoing',
                        ),
                        _buildDetailCard(Icons.layers, 'Season', 'Season 1'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // Episodes Section Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Text(
                  'Episodes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              /// Episode List (Keeping your original design)
              if (_isLoading)
                Container(
                  height: 200.h,
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Container(
                  height: 200.h,
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 40.sp,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _errorMessage,
                          style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        ElevatedButton(
                          onPressed: _loadPlaylistData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_playlistItems.isEmpty)
                Container(
                  height: 200.h,
                  padding: EdgeInsets.all(16.w),
                  child: Center(
                    child: Text(
                      'No episodes available',
                      style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._playlistItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final playlistItem = entry.value;
                  return _EpisodeTile(
                    playlistItem: playlistItem,
                    index: index,
                    totalEpisodes: _playlistItems.length,
                    imageUrl: widget.anime.thumbnail,
                    onTap: () => _navigateToPlayer(playlistItem),
                  );
                }),

              SizedBox(height: 100.h),
            ]),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final PlaylistItem playlistItem;
  final int index;
  final int totalEpisodes;
  final String imageUrl;
  final VoidCallback onTap;

  const _EpisodeTile({
    required this.playlistItem,
    required this.index,
    required this.totalEpisodes,
    required this.imageUrl,
    required this.onTap,
  });

  String formatEpisodeTitle(String rawTitle, int fallbackIndex) {
    final title = rawTitle.toLowerCase();

    // 1️⃣ RANGE DETECTION (Ep 01 ~ 03, EP 2-5, Episode 5 to 10, S01E01~E03)
    final rangePatterns = [
      RegExp(r'\bep?\s*0*(\d+)\s*[~\-–to]+\s*0*(\d+)\b'),
      RegExp(r'\be\s*0*(\d+)\s*[~\-–to]+\s*0*(\d+)\b'),
      RegExp(r'\bepisode\s*0*(\d+)\s*[~\-–to]+\s*0*(\d+)\b'),
      RegExp(r'\bs\d+e0*(\d+)\s*[~\-–to]+\s*(?:s\d+e)?0*(\d+)\b'),
    ];

    for (final reg in rangePatterns) {
      final m = reg.firstMatch(title);
      if (m != null) {
        final start = int.parse(m.group(1)!);
        final end = int.parse(m.group(2)!);
        return "Episodes $start–$end";
      }
    }

    // 2️⃣ SINGLE EPISODE DETECTION
    final singlePatterns = [
      RegExp(r'\bs\d+e(\d+)\b'),
      RegExp(r'\bepisode\s*(\d+)\b'),
      RegExp(r'\bep?\s*(\d+)\b'),
      RegExp(r'\be\s*0*(\d+)\b'),
      RegExp(r'\bpart\s*(\d+)\b'),
      RegExp(r'\bchapter\s*(\d+)\b'),
      RegExp(r'\b(\d+)\b'),
    ];

    for (final reg in singlePatterns) {
      final m = reg.firstMatch(title);
      if (m != null) {
        final ep = int.parse(m.group(1)!);
        return "Episode $ep";
      }
    }

    // 3️⃣ FALLBACK
    return "Episode ${fallbackIndex + 1}";
  }

  String _formatEpisodeNumber(int index, int total) {
    return formatEpisodeTitle(playlistItem.title, index);
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black, // Changed from white to black
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 160.w,
                      height: 90.h,
                      fit: BoxFit.cover,
                      fadeInDuration: Duration.zero,
                      errorWidget: (context, url, error) => Container(
                        width: 160.w,
                        height: 90.h,
                        decoration: BoxDecoration(
                          color:
                              Colors.grey[800], // Darker shade for dark theme
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.grey[400], // Lighter icon
                          size: 32.sp,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4.h,
                    right: 4.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withOpacity(
                          0.85,
                        ), // Changed color
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                      child: Text(
                        'HD+',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(width: 12.w),

              // Episode Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatEpisodeNumber(index, totalEpisodes),
                      style: TextStyle(
                        color: Color(0xFF9D4EDD), // Changed to deep purple
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      playlistItem.title,
                      style: TextStyle(
                        color: Colors.white, // Changed from black87 to white
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    _SlidingArrowsIndicator(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlidingArrowsIndicator extends StatefulWidget {
  const _SlidingArrowsIndicator();

  @override
  State<_SlidingArrowsIndicator> createState() =>
      _SlidingArrowsIndicatorState();
}

class _SlidingArrowsIndicatorState extends State<_SlidingArrowsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slideValue = _controller.value * 12;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OtaKuNexa',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13.sp,
              ), // Lighter grey
            ),
            SizedBox(width: 8.w),
            Stack(
              children: [
                Opacity(
                  opacity: 0.3,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Transform.translate(
                  offset: Offset(slideValue, 0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            Stack(
              children: [
                Opacity(
                  opacity: 0.3,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Color(0xFF9D4EDD), // Changed to deep purple
                  ),
                ),
                Transform.translate(
                  offset: Offset(slideValue - 12, 0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Color(0xFF9D4EDD), // Changed to deep purple
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
