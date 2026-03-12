import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/Youtube/Shorts/shorts_model.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startapp_sdk/startapp.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// 🔹 Wrapper
class FeedItem {
  final ShortVideo? video;
  final bool isAd;
  FeedItem({this.video, this.isAd = false});
}

class AnimeShortsPage extends StatefulWidget {
  const AnimeShortsPage({super.key});

  @override
  State<AnimeShortsPage> createState() => _AnimeShortsPageState();
}

class _AnimeShortsPageState extends State<AnimeShortsPage> {
  Set<String> _likedVideoIds = {};
  final List<FeedItem> _feedItems = [];
  final PageController _pageController = PageController();
  int _focusedIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _loadLikedVideos();
    _initLoadSequence();
  }

  Future<void> _initLoadSequence() async {
    await _loadJsonBatch('assets/content/short_a.json');
    if (mounted) {
      _loadJsonBatch('assets/content/shorts_data_small.json');
    }
  }

  Future<void> _loadJsonBatch(String assetPath) async {
    try {
      final String response = await rootBundle.loadString(assetPath);
      final List<FeedItem> processedBatch = await compute(
        _parseAndInjectAds,
        response,
      );

      if (mounted) {
        setState(() {
          _feedItems.addAll(processedBatch);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  static List<FeedItem> _parseAndInjectAds(String jsonString) {
    final List<dynamic> data = jsonDecode(jsonString);
    List<ShortVideo> newVideos = data
        .map((json) => ShortVideo.fromJson(json))
        .toList();
    newVideos.shuffle();

    List<FeedItem> result = [];
    int counter = 0;
    int nextAdTarget = Random().nextInt(7) + 6;

    for (var video in newVideos) {
      result.add(FeedItem(video: video));
      counter++;
      if (counter >= nextAdTarget) {
        result.add(FeedItem(isAd: true));
        counter = 0;
        nextAdTarget = Random().nextInt(7) + 6;
      }
    }
    return result;
  }

  Future<void> _loadLikedVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedLikes = prefs.getStringList('liked_videos');
    if (storedLikes != null && mounted) {
      setState(() => _likedVideoIds = storedLikes.toSet());
    }
  }

  Future<void> _toggleLike(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_likedVideoIds.contains(videoId)) {
        _likedVideoIds.remove(videoId);
      } else {
        _likedVideoIds.add(videoId);
      }
    });
    await prefs.setStringList('liked_videos', _likedVideoIds.toList());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _isLoading && _feedItems.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _feedItems.length,
                  physics: const ClampingScrollPhysics(), // Snappy scroll
                  allowImplicitScrolling: false,
                  onPageChanged: (index) {
                    if (mounted) setState(() => _focusedIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _feedItems[index];
                    if (item.isAd) {
                      return const AdContainer();
                    } else {
                      return ShortVideoItem(
                        video: item.video!,
                        isLiked: _likedVideoIds.contains(item.video!.videoId),
                        onLikeToggle: () => _toggleLike(item.video!.videoId),
                        isActive: _focusedIndex == index,
                      );
                    }
                  },
                ),

          // Top Overlay
          Positioned(
            top: 50.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "OtaKuNexa",
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 15.w),
                Container(width: 1.w, height: 14.h, color: Colors.white24),
                SizedBox(width: 15.w),
                Text(
                  "For You",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// 💰 AD CONTAINER
// ---------------------------------------------------------
class AdContainer extends StatefulWidget {
  const AdContainer({super.key});

  @override
  State<AdContainer> createState() => _AdContainerState();
}

class _AdContainerState extends State<AdContainer> {
  StartAppBannerAd? _mrecAd;
  var startAppSdk = StartAppSdk();

  @override
  void initState() {
    super.initState();
    _loadMrecAd();
  }

  void _loadMrecAd() {
    startAppSdk
        .loadBannerAd(StartAppBannerType.MREC)
        .then((ad) {
          if (mounted) {
            setState(() {
              _mrecAd = ad;
            });
          }
        })
        .catchError((e) {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Container(
          width: 300,
          height: 250,
          color: Colors.grey[900],
          child: _mrecAd != null
              ? StartAppBanner(_mrecAd!)
              : const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// ⚡ CRASH-PROOF VIDEO ITEM
// ---------------------------------------------------------
class ShortVideoItem extends StatefulWidget {
  final ShortVideo video;
  final bool isLiked;
  final VoidCallback onLikeToggle;
  final bool isActive;

  const ShortVideoItem({
    super.key,
    required this.video,
    required this.isLiked,
    required this.onLikeToggle,
    required this.isActive,
  });

  @override
  State<ShortVideoItem> createState() => _ShortVideoItemState();
}

class _ShortVideoItemState extends State<ShortVideoItem> {
  YoutubePlayerController? _controller;
  bool _isPlayerReady = false;
  Timer? _debounceTimer;

  @override
  void didUpdateWidget(ShortVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _startLoadingTimer();
    }
    if (!widget.isActive && oldWidget.isActive) {
      _disposePlayer();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _startLoadingTimer();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startLoadingTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted && widget.isActive) {
        _initializeController();
      }
    });
  }

  void _disposePlayer() {
    _debounceTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    if (mounted) {
      setState(() => _isPlayerReady = false);
    }
  }

  void _initializeController() {
    if (_controller != null) return;

    _controller =
        YoutubePlayerController(
          initialVideoId: widget.video.videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            loop: true,
            mute: false,
            hideControls: true,
            enableCaption: false,
            disableDragSeek: true,
          ),
        )..addListener(() {
          if (!mounted) return;
          if (_controller != null &&
              _controller!.value.isReady &&
              !_isPlayerReady) {
            setState(() => _isPlayerReady = true);
          }
        });

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String thumbnailUrl =
        'https://img.youtube.com/vi/${widget.video.videoId}/hqdefault.jpg';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Container(color: Colors.black),

        // Video / Thumbnail Logic
        Center(
          child: AspectRatio(
            aspectRatio: 9 / 16,
            child: _controller != null
                ? YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: false,
                  )
                : Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => Container(color: Colors.black),
                  ),
          ),
        ),

        // Controls
        GestureDetector(
          onTap: () {
            if (_controller != null && _isPlayerReady) {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            }
          },
          onDoubleTap: widget.onLikeToggle,
          child: Container(color: Colors.transparent),
        ),

        // Gradient
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black26, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // ---------------------------------------------
        // ⚡ RIGHT SIDEBAR (Restored Buttons)
        // ---------------------------------------------
        Positioned(
          right: 12.w,
          bottom: 110.h,
          child: Column(
            children: [
              _buildProfilePic(),
              SizedBox(height: 25.h),

              // Like Button
              _buildAction(
                icon: widget.isLiked ? Icons.favorite : Icons.favorite_border,
                label: widget.isLiked ? "Liked" : "Like",
                color: widget.isLiked ? Colors.red : Colors.white,
                onTap: widget.onLikeToggle,
              ),
              SizedBox(height: 25.h),

              // Comment Button (Disabled/Dummy)
              _buildAction(
                icon: Icons.comment_rounded,
                label: "Comment",
                color: Colors.white.withOpacity(0.6), // Dimmed to look disabled
                onTap: () {
                  // Optional: Show "Coming Soon" toast here
                },
              ),
              SizedBox(height: 25.h),

              // Share Button
              _buildAction(
                icon: Icons.reply_rounded,
                label: "Share",
                onTap: () {
                  ShareService.shareAppApk(
                    type: ShareType.shorts,
                    animeTitle: widget.video.title,
                    context: context,
                  );
                },
              ),
              SizedBox(height: 35.h),

              // Vinyl Disc (Restored)
              _buildVinylDisc(),
            ],
          ),
        ),

        // Bottom Text Info
        Positioned(
          left: 16.w,
          bottom: 24.h,
          right: 90.w,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "@OtakuNexa",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Icon(Icons.verified, color: Colors.blueAccent, size: 16.sp),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                widget.video.title,
                maxLines: 2,
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.music_note, color: Colors.white, size: 14.sp),
                  SizedBox(width: 8.w),
                  Text(
                    "OtakuNexa !Original Audio",
                    style: TextStyle(color: Colors.white, fontSize: 13.sp),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 UI HELPERS (Restored)
  Widget _buildProfilePic() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 11.h),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.w),
          ),
          child: CircleAvatar(
            radius: 22.r,
            backgroundImage: const AssetImage('assets/logo/logo2.png'),
            backgroundColor: Colors.black,
          ),
        ),
        Positioned(
          bottom: 0,
          child: CircleAvatar(
            radius: 11.r,
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.add, color: Colors.white, size: 15.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildVinylDisc() {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Colors.black87,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[800]!, width: 6.w),
      ),
      child: CircleAvatar(
        radius: 14.r,
        backgroundImage: const AssetImage('assets/logo/logo2.png'),
        backgroundColor: Colors.grey,
      ),
    );
  }

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32.sp, // Slightly larger for better touch target
            shadows: const [Shadow(blurRadius: 8, color: Colors.black54)],
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ],
      ),
    );
  }
}
