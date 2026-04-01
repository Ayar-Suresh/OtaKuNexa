import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:otakunexa/youtube/Episodes/model/playlist_item.dart';
import 'package:otakunexa/youtube/player/buttons/button_model.dart';
import 'package:otakunexa/youtube/player/buttons/button_state_sharedprefs.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'youtube_controller.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final PlaylistItem currentVideo;
  final List<PlaylistItem> playlistItems;
  final String playlistThumbnail;

  const YoutubePlayerScreen({
    super.key,
    required this.currentVideo,
    required this.playlistItems,
    required this.playlistThumbnail,
  });

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubeController customController;
  late PlaylistItem _currentVideo;
  bool _showPlaylist = true;
  ActionState actionState = ActionState();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentVideo = widget.currentVideo;
    customController = YoutubeController(_currentVideo.videoId);
    _loadSavedState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _loadSavedState() async {
    try {
      actionState = await ActionPrefs.loadState();
    } catch (e) {
      actionState = ActionState();
      debugPrint('Failed to load action state: $e');
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  void _toggleAction(String key) {
    setState(() {
      switch (key) {
        case "smash":
          actionState.smashed = !actionState.smashed;
          if (actionState.smashed) {
            actionState.trashed = false;
          }
          break;

        case "trash":
          actionState.trashed = !actionState.trashed;
          if (actionState.trashed) {
            actionState.smashed = false;
          }
          break;

        case "save":
          actionState.saved = !actionState.saved;
          break;
      }
    });

    ActionPrefs.saveState(actionState);
  }

  void _shareVideo() {
    ShareService.shareAppApk(
      type: ShareType.anime,
      animeTitle: widget.currentVideo.title, // Replace with your variable name
      context: context,
    );
  }

  @override
  void dispose() {
    try {
      customController.dispose();
    } catch (e) {
      debugPrint('Error disposing controller: $e');
    }
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _playVideo(PlaylistItem video) {
    setState(() {
      _currentVideo = video;
    });
    customController.loadVideo(video.videoId);
  }

  int get _currentIndex {
    final index = widget.playlistItems.indexWhere(
      (item) => item.videoId == _currentVideo.videoId,
    );
    return index >= 0 ? index : 0;
  }

  void _playNext() {
    if (_currentIndex < widget.playlistItems.length - 1) {
      _playVideo(widget.playlistItems[_currentIndex + 1]);
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _playVideo(widget.playlistItems[_currentIndex - 1]);
    }
  }

  String _extractEpisodeNumber(String title) {
    final patterns = [
      RegExp(
        r'(?:Episode|EP|E|Ch|Chapter|#)\s*[:\-\s]*?(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'ep\.\s*(\d+)', caseSensitive: false),
      RegExp(r'\[(\d+)\]'),
      RegExp(r'- (\d+)'),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(title);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!;
      }
    }
    return '';
  }

  String _getEpisodeLabel(PlaylistItem item, int index, int total) {
    final episodeNum = _extractEpisodeNumber(item.title);
    if (episodeNum.isNotEmpty) {
      return 'Episode $episodeNum';
    }
    if (index >= 0 && index < total) {
      return 'Episode ${index + 1}';
    }
    return 'Episode';
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
        controller: customController.player,
        showVideoProgressIndicator: true,
        progressIndicatorColor: const Color(0xFF9D4EDD),
        progressColors: const ProgressBarColors(
          playedColor: Color(0xFF9D4EDD),
          handleColor: Color(0xFF9D4EDD),
        ),
        onReady: () {
          debugPrint("Player Ready: ${_currentVideo.videoId}");
        },
        onEnded: (data) {
          _playNext();
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.6),
            elevation: 0,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _currentVideo.title.isNotEmpty
                  ? _currentVideo.title
                  : 'Now Playing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.cast, color: Colors.white70, size: 24.sp),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white70, size: 24.sp),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [
              // Video Player
              player,

              // Video Info Section - OPTIMIZED WITH CustomScrollView
              Expanded(
                child: CustomScrollView(
                  // ⚡ Key performance improvement
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Video Details Header
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: Container(
                          padding: EdgeInsets.all(16.w), // Responsive Padding
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withOpacity(0.4),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16.r),
                              bottomRight: Radius.circular(16.r),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getEpisodeLabel(
                                  _currentVideo,
                                  _currentIndex,
                                  widget.playlistItems.length,
                                ),
                                style: TextStyle(
                                  color: const Color(0xFF9D4EDD),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                _currentVideo.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              const _AnimatedArrowIndicator(),
                              SizedBox(height: 16.h),
                              Row(
                                children: [
                                  _ActionButton(
                                    icon: actionState.smashed
                                        ? Icons.thumb_up
                                        : Icons.thumb_up_outlined,
                                    label: 'Like',
                                    isActive: actionState.smashed,
                                    onTap: () => _toggleAction("smash"),
                                  ),
                                  SizedBox(width: 16.w),
                                  _ActionButton(
                                    icon: actionState.trashed
                                        ? Icons.thumb_down
                                        : Icons.thumb_down_outlined,
                                    label: 'Dislike',
                                    isActive: actionState.trashed,
                                    onTap: () => _toggleAction("trash"),
                                  ),
                                  SizedBox(width: 16.w),
                                  _ActionButton(
                                    icon: Icons.share_outlined,
                                    label: 'Share',
                                    onTap: _shareVideo,
                                  ),
                                  const Spacer(),
                                  _ActionButton(
                                    icon: actionState.saved
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                    label: 'Save',
                                    isActive: actionState.saved,
                                    onTap: () => _toggleAction("save"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Navigation Buttons
                    SliverToBoxAdapter(
                      child: RepaintBoundary(
                        child: Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _currentIndex > 0
                                      ? _playPrevious
                                      : null,
                                  icon: Icon(Icons.skip_previous, size: 20.sp),
                                  label: Text(
                                    'Previous',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF9D4EDD),
                                    disabledForegroundColor: Colors.grey[700],
                                    side: BorderSide(
                                      color: _currentIndex > 0
                                          ? const Color(0xFF9D4EDD)
                                          : Colors.grey[800]!,
                                      width: 1.w,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _currentIndex <
                                          widget.playlistItems.length - 1
                                      ? _playNext
                                      : null,
                                  icon: Icon(Icons.skip_next, size: 20.sp),
                                  label: Text(
                                    'Next',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9D4EDD),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.grey[900],
                                    disabledForegroundColor: Colors.grey[700],
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Divider(
                        height: 1.h,
                        thickness: 1.h,
                        color: Colors.grey[900],
                      ),
                    ),

                    // Playlist Header
                    SliverToBoxAdapter(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _showPlaylist = !_showPlaylist;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.playlist_play,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'All Episodes',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      '${widget.playlistItems.length} episodes',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showPlaylist
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.grey[400],
                                size: 24.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ⚡ OPTIMIZED: SliverList with builder instead of mapping all items
                    if (_showPlaylist)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = widget.playlistItems[index];
                            return RepaintBoundary(
                              key: ValueKey(item.videoId),
                              child: _PlaylistEpisodeTile(
                                playlistItem: item,
                                index: index,
                                totalEpisodes: widget.playlistItems.length,
                                imageUrl: widget.playlistThumbnail,
                                isCurrentlyPlaying:
                                    item.videoId == _currentVideo.videoId,
                                onTap: () => _playVideo(item),
                              ),
                            );
                          },
                          childCount: widget.playlistItems.length,
                          addRepaintBoundaries: true,
                          addAutomaticKeepAlives: false,
                          addSemanticIndexes: false,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistEpisodeTile extends StatelessWidget {
  final PlaylistItem playlistItem;
  final int index;
  final int totalEpisodes;
  final String imageUrl;
  final bool isCurrentlyPlaying;
  final VoidCallback onTap;

  const _PlaylistEpisodeTile({
    required this.playlistItem,
    required this.index,
    required this.totalEpisodes,
    required this.imageUrl,
    required this.isCurrentlyPlaying,
    required this.onTap,
  });

  String formatEpisodeTitle(String rawTitle, int fallbackIndex) {
    final title = rawTitle.toLowerCase();

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

    return "Episode ${fallbackIndex + 1}";
  }

  String _formatEpisodeNumber(int index, int total) {
    return formatEpisodeTitle(playlistItem.title, index);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrentlyPlaying
          ? const Color(0xFF9D4EDD).withOpacity(0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // ⚡ Fixed height for better performance
          height: 106.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isCurrentlyPlaying
                    ? const Color(0xFF9D4EDD)
                    : Colors.transparent,
                width: 3.w,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail - OPTIMIZED
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 160.w,
                      height: 90.h,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 200),
                      errorWidget: (context, url, error) => Container(
                        width: 160.w,
                        height: 90.h,
                        color: Colors.grey[900],
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.grey[600],
                          size: 32.sp,
                        ),
                      ),
                    ),
                    if (isCurrentlyPlaying)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 40.sp,
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
                          color: Colors.black.withOpacity(0.85),
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
              ),

              SizedBox(width: 12.w),

              // Episode Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatEpisodeNumber(index, totalEpisodes),
                          style: TextStyle(
                            color: isCurrentlyPlaying
                                ? const Color(0xFF9D4EDD)
                                : Colors.grey[500],
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isCurrentlyPlaying) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9D4EDD),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'NOW PLAYING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      playlistItem.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    // ⚡ Only show animation for visible items
                    if (isCurrentlyPlaying)
                      const _SlidingArrowsIndicator()
                    else
                      Text(
                        'OtaKuNexa',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12.sp,
                        ),
                      ),
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

class _AnimatedArrowIndicator extends StatefulWidget {
  const _AnimatedArrowIndicator();

  @override
  State<_AnimatedArrowIndicator> createState() =>
      _AnimatedArrowIndicatorState();
}

class _AnimatedArrowIndicatorState extends State<_AnimatedArrowIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
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
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: _controller.value,
              child: Icon(
                Icons.arrow_forward,
                size: 16.sp,
                color: const Color(0xFF9D4EDD),
              ),
            ),
            SizedBox(width: 4.w),
            Opacity(
              opacity: (_controller.value - 0.3).clamp(0.0, 1.0),
              child: Icon(
                Icons.arrow_forward,
                size: 16.sp,
                color: const Color(0xFF9D4EDD),
              ),
            ),
            SizedBox(width: 4.w),
            Opacity(
              opacity: (_controller.value - 0.6).clamp(0.0, 1.0),
              child: Icon(
                Icons.arrow_forward,
                size: 16.sp,
                color: const Color(0xFF9D4EDD),
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
        // Scaled slide value
        final slideValue = _controller.value * 12.w;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'OtaKuNexa',
              style: TextStyle(color: Colors.grey[500], fontSize: 13.sp),
            ),
            SizedBox(width: 8.w),
            Stack(
              children: [
                Opacity(
                  opacity: 0.3,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.grey[700],
                  ),
                ),
                Transform.translate(
                  offset: Offset(slideValue, 0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: const Color(0xFF9D4EDD),
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
                    color: Colors.grey[700],
                  ),
                ),
                Transform.translate(
                  offset: Offset(slideValue - 12.w, 0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: const Color(0xFF9D4EDD),
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
