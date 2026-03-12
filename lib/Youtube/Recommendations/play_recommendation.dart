import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/OuterShores/metadata/anime_horizontal_section.dart';
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:otakunexa/OuterShores/service/categ_manager.dart';
import 'package:otakunexa/Youtube/Recommendations/recommendations_model.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final Recommendations_Model videos;

  const YoutubePlayerScreen({super.key, required this.videos});

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen>
    with SingleTickerProviderStateMixin {
  late YoutubePlayerController _controller;
  bool isLoading = true;
  bool _showAvailableAnimes = true;
  CategoryConfig? _randomCategory;

  // Action state
  bool isLiked = false;
  bool isDisliked = false;
  bool isSaved = false;
  bool _isCategoriesLoading = true;
  final CategoryManager _categoryManager = CategoryManager();

  // Arrow animation
  late AnimationController _arrowController;

  @override
  void initState() {
    super.initState();

    _controller = YoutubePlayerController(
      initialVideoId: widget.videos.videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );

    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _loadCategories();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => isLoading = false);
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isCategoriesLoading = true;
    });

    await _categoryManager.loadAllCategories();

    if (!mounted) return;

    setState(() {
      _isCategoriesLoading = false;
      // Pick one random category only for this page
      final categories = _categoryManager.categories;
      if (categories.isNotEmpty) {
        final randomIndex = Random().nextInt(categories.length);
        _randomCategory = categories[randomIndex];
      }
    });
  }

  void _shareVideo() {
    ShareService.shareAppApk(
      type: ShareType.anime,
      animeTitle: widget.videos.title, // Replace with your variable name
      context: context,
    );
  }

  void _toggleAction(String key) {
    setState(() {
      switch (key) {
        case "like":
          isLiked = !isLiked;
          if (isLiked) isDisliked = false;
          break;
        case "dislike":
          isDisliked = !isDisliked;
          if (isDisliked) isLiked = false;
          break;
        case "save":
          isSaved = !isSaved;
          break;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _arrowController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF9D4EDD)),
        ),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF9D4EDD),
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.videos.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Video Player
                player,

                // Video Info Section
                Container(
                  padding: EdgeInsets.all(16.w),
                  color: const Color(0xFF0A0A0A),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommendations',
                        style: TextStyle(
                          color: const Color(0xFF9D4EDD),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        widget.videos.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Row(
                        children: [
                          _ActionButton(
                            icon: isLiked
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            label: 'Like',
                            isActive: isLiked,
                            onTap: () => _toggleAction("like"),
                          ),
                          SizedBox(width: 16.w),
                          _ActionButton(
                            icon: isDisliked
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            label: 'Dislike',
                            isActive: isDisliked,
                            onTap: () => _toggleAction("dislike"),
                          ),
                          SizedBox(width: 16.w),
                          _ActionButton(
                            icon: Icons.share_outlined,
                            label: 'Share',
                            onTap: _shareVideo,
                          ),
                          const Spacer(),
                          _ActionButton(
                            icon: isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            label: 'Save',
                            isActive: isSaved,
                            onTap: () => _toggleAction("save"),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      _AnimatedArrow(controller: _arrowController),
                    ],
                  ),
                ),

                // Sponsor ad placeholder
                Container(
                  margin: EdgeInsets.symmetric(
                    vertical: 12.h,
                    horizontal: 16.w,
                  ),
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Sponsor Ad',
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ),
                ),

                // Available Animes section with toggle
                InkWell(
                  onTap: () => setState(
                    () => _showAvailableAnimes = !_showAvailableAnimes,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    color: const Color(0xFF0A0A0A),
                    child: Row(
                      children: [
                        Icon(
                          Icons.video_library,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Animes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Evergreen',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _showAvailableAnimes
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.grey[400],
                          size: 24.sp,
                        ),
                      ],
                    ),
                  ),
                ),

                // Show random category only
                if (_showAvailableAnimes && _randomCategory != null)
                  _buildCategorySection(_randomCategory!),

                // Bottom Padding for scroll
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategorySection(CategoryConfig category) {
    final animeData = _categoryManager.getAnimeData(category.id);
    final isLoading =
        _categoryManager.isLoading(category.id) || _isCategoriesLoading;

    return AnimeHorizontalSection(
      title: category.title,
      animeList:
          animeData?.map((data) => AnimeModel(data: data)).toList() ?? [],
      isLoading: isLoading,
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF9D4EDD) : Colors.white70,
              size: 24.sp,
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF9D4EDD) : Colors.white70,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedArrow extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedArrow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: controller.value,
              child: Icon(
                Icons.arrow_forward,
                color: const Color(0xFF9D4EDD),
                size: 16.sp,
              ),
            ),
            SizedBox(width: 4.w),
            Opacity(
              opacity: (controller.value - 0.3).clamp(0.0, 1.0),
              child: Icon(
                Icons.arrow_forward,
                color: const Color(0xFF9D4EDD),
                size: 16.sp,
              ),
            ),
            SizedBox(width: 4.w),
            Opacity(
              opacity: (controller.value - 0.6).clamp(0.0, 1.0),
              child: Icon(
                Icons.arrow_forward,
                color: const Color(0xFF9D4EDD),
                size: 16.sp,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Watching',
              style: TextStyle(
                color: const Color(0xFF9D4EDD),
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}
