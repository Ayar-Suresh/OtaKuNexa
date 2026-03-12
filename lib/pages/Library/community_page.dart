import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added Import
import 'package:google_fonts/google_fonts.dart';
import 'package:otakunexa/Reddit/service/reddit_service.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:share_plus/share_plus.dart';

// --- THEME ---
class AppTheme {
  static const bg = Color(0xFF000000);
  static const cardSurface = Color(0xFF0A0A0A);
  static const primaryNeon = Color(0xFF9D4EDD);
  static const accentNeon = Color(0xFF00B4D8);
  static const textMain = Color(0xFFEAEAEA);
  static const textSub = Color(0xFFAAAAAA);
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final RedditService _service = RedditService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;

  // Track the ID of the open post
  String? _expandedPostId;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 500.h) {
        _loadMore();
      }
    });
  }

  Future<void> _loadInitial({String? query}) async {
    setState(() => _isLoading = true);
    final posts = await _service.fetchPosts(query: query);
    if (mounted) {
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    final morePosts = await _service.fetchPosts(isLoadMore: true);
    if (mounted) {
      setState(() {
        _posts.addAll(morePosts);
        _isLoadingMore = false;
      });
    }
  }

  void _togglePostExpansion(String postId) {
    setState(() {
      if (_expandedPostId == postId) {
        _expandedPostId = null; // Close
      } else {
        _expandedPostId = postId; // Open
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- FIXED: PERFECT BACK BUTTON LOGIC ---
    return PopScope(
      // If _expandedPostId is NOT null, we CANNOT pop (we block it).
      canPop: _expandedPostId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return; // If the system already popped, do nothing.

        // If we blocked the pop, it means a post is open. Close it.
        setState(() {
          _expandedPostId = null;
        });
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        appBar: AppBar(
          backgroundColor: AppTheme.cardSurface,
          elevation: 0,
          title: Container(
            height: 36.h,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => _loadInitial(query: value),
              decoration: InputDecoration(
                hintText: "Search 'Anime where MC is Villain'",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14.sp,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18.sp,
                  color: Colors.white54,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(top: 2.h),
              ),
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 12.0.w),
              child: Image.asset(
                'assets/logo/logo.png',
                width: 70.w,
                height: 50.h,
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              )
            : ListView.separated(
                controller: _scrollController,
                itemCount: _posts.length + 1,
                separatorBuilder: (c, i) =>
                    Divider(height: 8.h, thickness: 8.h, color: AppTheme.bg),
                itemBuilder: (context, index) {
                  if (index == _posts.length) {
                    return _isLoadingMore
                        ? Padding(
                            padding: EdgeInsets.all(20.w),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryNeon,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  }

                  final post = _posts[index];
                  return _RedditStyleCard(
                    post: post,
                    service: _service,
                    isExpanded: post.id == _expandedPostId,
                    onToggleExpand: () => _togglePostExpansion(post.id),
                  );
                },
              ),
      ),
    );
  }
}

class _RedditStyleCard extends StatefulWidget {
  final CommunityPost post;
  final RedditService service;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _RedditStyleCard({
    required this.post,
    required this.service,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  State<_RedditStyleCard> createState() => _RedditStyleCardState();
}

class _RedditStyleCardState extends State<_RedditStyleCard> {
  bool _loadingComments = false;
  List<CommunityComment>? _comments;

  @override
  void didUpdateWidget(covariant _RedditStyleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded && _comments == null) {
      _fetchComments();
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _loadingComments = true);
    try {
      final c = await widget.service.fetchComments(widget.post.id);
      if (mounted) {
        setState(() {
          _comments = c;
          _loadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  void _handleVotePress() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent.withOpacity(0.8),
        content: const Text(
          "Voting is currently disabled in Guest Mode.",
          style: TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _sendAPk() {
    ShareService.shareAppApk(
      type: ShareType.shorts,
      animeTitle: '', // Context for the text
      context: context,
    );
  }

  void _sharePostContent() {
    final String text =
        "${widget.post.title}\n\nCheck this out on OtakuNexa:\n${widget.post.thumbnail ?? ''}";
    Share.share(text);
    Navigator.pop(context);
  }

  void _handleSharePress() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "Share Post",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.accentNeon),
              title: const Text(
                "Send Apk",
                style: TextStyle(color: Colors.white),
              ),
              onTap: _sendAPk,
            ),
            ListTile(
              leading: const Icon(Icons.share, color: AppTheme.primaryNeon),
              title: const Text(
                "Share Post",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                "Ask To Friend",
                style: TextStyle(color: Colors.grey, fontSize: 12.sp),
              ),
              onTap: _sharePostContent,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage =
        widget.post.thumbnail != null &&
        widget.post.thumbnail!.startsWith('http');

    return Container(
      color: AppTheme.cardSurface,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14.r,
                  backgroundColor: Colors.grey[900],
                  backgroundImage: const NetworkImage(
                    "https://www.redditstatic.com/avatars/defaults/v2/avatar_default_0.png",
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "r/Anime",
                      style: GoogleFonts.inter(
                        color: AppTheme.textMain,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    Text(
                      "u/${widget.post.author}",
                      style: TextStyle(
                        color: AppTheme.textSub,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (widget.post.isOffline)
                  _buildBadge("OTAKUNEXA", AppTheme.primaryNeon)
                else
                  _buildBadge("REDDIT", Colors.blueGrey),
              ],
            ),
          ),

          // --- FIXED: CLICKABLE CONTENT AREA (Title + Image + Body) ---
          GestureDetector(
            onTap:
                widget.onToggleExpand, // <--- CLICKING CONTENT OPENS COMMENTS
            behavior: HitTestBehavior
                .opaque, // Ensures clicks on empty space are caught
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                  child: Text(
                    widget.post.title,
                    style: GoogleFonts.inter(
                      color: AppTheme.textMain,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),

                // MEDIA
                if (hasImage)
                  Padding(
                    padding: EdgeInsets.only(top: 6.h, bottom: 6.h),
                    child: CachedNetworkImage(
                      imageUrl: widget.post.thumbnail!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(height: 250.h, color: Colors.grey[900]),
                      errorWidget: (_, __, ___) => Container(
                        height: 200.h,
                        color: Colors.grey[900],
                        child: const Icon(Icons.error, color: Colors.white54),
                      ),
                    ),
                  )
                else if (widget.post.body.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 4.h,
                    ),
                    child: Text(
                      widget.post.body,
                      maxLines: widget.isExpanded ? 100 : 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFFCCCCCC),
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ACTION BAR
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _handleVotePress,
                  child: _buildPill(
                    borderColor: widget.isExpanded
                        ? Colors.grey[800]!
                        : Colors.grey[900]!,
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 20.sp,
                          color: AppTheme.textMain,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          widget.post.upvotes,
                          style: TextStyle(
                            color: AppTheme.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          width: 1.w,
                          height: 14.h,
                          color: Colors.grey[800],
                        ),
                        SizedBox(width: 6.w),
                        Icon(
                          Icons.arrow_downward_rounded,
                          size: 20.sp,
                          color: AppTheme.textMain,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),

                // Comment Pill (Also Toggles)
                GestureDetector(
                  onTap: widget.onToggleExpand,
                  child: _buildPill(
                    backgroundColor: widget.isExpanded
                        ? Colors.white.withOpacity(0.1)
                        : Colors.transparent,
                    borderColor: widget.isExpanded
                        ? Colors.white24
                        : Colors.grey[900]!,
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18.sp,
                          color: widget.isExpanded
                              ? Colors.white
                              : Colors.white70,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          widget.post.commentCount,
                          style: TextStyle(
                            color: widget.isExpanded
                                ? Colors.white
                                : Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _handleSharePress,
                  child: _buildPill(
                    borderColor: Colors.grey[900]!,
                    child: Row(
                      children: [
                        Icon(
                          Icons.share_outlined,
                          size: 18.sp,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          "Share",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // COMMENTS
          if (widget.isExpanded) _buildCommentSection(),
        ],
      ),
    );
  }

  Widget _buildCommentSection() {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_loadingComments)
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.w)),
            )
          else if (_comments == null || _comments!.isEmpty)
            Padding(
              padding: EdgeInsets.all(20.w),
              child: const Center(
                child: Text(
                  "No comments yet.",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments!.length,
              itemBuilder: (context, index) {
                final c = _comments![index];
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[900]!),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 10.r,
                        backgroundColor: Colors.grey[800],
                        child: Text(
                          c.author[0],
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.author,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                if (c.isOp)
                                  Text(
                                    "OP",
                                    style: TextStyle(
                                      color: AppTheme.primaryNeon,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  c.score,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              c.body,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          // "Close Comments" Button at bottom
          InkWell(
            onTap: widget.onToggleExpand,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              color: Colors.grey[900],
              child: const Center(
                child: Icon(Icons.keyboard_arrow_up, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1.w),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildPill({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: borderColor ?? Colors.grey[900]!),
      ),
      child: child,
    );
  }
}
