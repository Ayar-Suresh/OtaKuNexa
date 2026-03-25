import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/OuterShores/model/metadate_model.dart';
import 'package:otakunexa/OuterShores/teleg/teleg_service.dart';
import 'package:otakunexa/pages/Library/req_and_supply.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';

import 'package:showcaseview/showcaseview.dart';

// Import your service file here
// import 'path/to/anime_download_service.dart';

class AnimeAboutPage extends StatefulWidget {
  final AnimeModel selectedAnime;
  const AnimeAboutPage({super.key, required this.selectedAnime});

  @override
  State<AnimeAboutPage> createState() => _AnimeAboutPageState();
}

class _AnimeAboutPageState extends State<AnimeAboutPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isDescriptionExpanded = false;
  String? _expandedDetailLabel;

  bool _isLoadingIndex = true;
  bool _isAvailable = false;
  Map<String, dynamic>? _foundAnimeData;
  String? _animeTitleKey;
  String _currentSelectedSeason = "1";

  // Default Language
  String _languageInfo = "Multi-Lang";

  // 🚦 NEW: Visibility State for Button
  bool _showSwitchButton = false;
  
  final GlobalKey _languageKey = GlobalKey();
  final GlobalKey _downloadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Give SassyBot Context
    SassyAiService.instance.currentAnimeContext = widget.selectedAnime.data.title;

    // Trigger SassyBot Roast
    SassyAiService.instance.triggerAnimeRoast(widget.selectedAnime.data.titleEnglish);

    // Delay fetch to ensure 'context' is valid
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });

    // Check if we should show the button immediately
    _checkSwitchButtonVisibility();
  }

  // 🚦 Logic to hide button if server is stable
  void _checkSwitchButtonVisibility() async {
    bool show = await AnimeDownloadService.shouldShowSwitchButton();
    if (mounted) setState(() => _showSwitchButton = show);
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoadingIndex = true);

    String malId = widget.selectedAnime.data.malId.toString();

    // Pass 'context' here so the Service can show "Finding Server..." prompt
    final result = await AnimeDownloadService.checkAvailability(
      malId,
      context: context,
    );

    // Re-check visibility after fetch attempt (status might change)
    _checkSwitchButtonVisibility();

    if (mounted) {
      setState(() {
        _isLoadingIndex = false;
        SassyAiService.instance.isCurrentAnimeAvailable = result != null;
        if (result != null) {
          _isAvailable = true;
          _foundAnimeData = result['data'];
          _animeTitleKey = result['titleKey'];

          // Ghost Automation: Scroll to batches physically 
          if (SassyAiService.instance.isGhostNavigating) {
            Future.delayed(const Duration(milliseconds: 600), () {
              if (mounted) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutBack,
                );
              }
            });
          }

          // Extract Language Logic
          if (_foundAnimeData != null && _foundAnimeData!['seasons'] != null) {
            Map<String, dynamic> seasons = _foundAnimeData!['seasons'];
            for (var seasonKey in seasons.keys) {
              var seasonData = seasons[seasonKey];
              if (seasonData['language'] != null) {
                String lang = seasonData['language'].toString();
                _languageInfo = lang
                    .replaceAll("/", " | ")
                    .replaceAll("English", "Eng");
                break;
              }
            }
          }
        } else {
          _isAvailable = false;
        }
      });
    }
  }

  // --- Logic to Handle Manual Switch ---
  void _handleManualServerSwitch() async {
    bool refreshed = await AnimeDownloadService.openManualServerDialog(context);

    if (refreshed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Server Changed! Refreshing data..."),
            backgroundColor: Colors.green,
          ),
        );
        _fetchData(); // Restart the hunt with the new server
      }
    }
  }

  Widget _buildStarRating(double rating) {
    double starCount = rating / 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        double fill = (starCount - index).clamp(0.0, 1.0);
        return Stack(
          children: [
            Icon(Icons.star_border, color: Colors.grey[700], size: 20.sp),
            ClipRect(
              clipper: _StarClipper(fill),
              child: Icon(Icons.star, color: Colors.deepPurple, size: 20.sp),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 520.h,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18.sp,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.network(
              widget.selectedAnime.data.images.jpg.largeImageUrl.isNotEmpty
                  ? widget.selectedAnime.data.images.jpg.largeImageUrl
                  : widget.selectedAnime.data.images.jpg.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) =>
                  Container(color: Colors.grey[900]),
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.85, 1.0],
                ),
              ),
            ),

            // Content Overlay
            Positioned(
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- BADGES ROW ---
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: [
                      // 1. Availability Badge
                      if (_isLoadingIndex)
                        SizedBox(
                          height: 20.h,
                          width: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: _isAvailable
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF1744),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isAvailable
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                size: 12.sp,
                                color: Colors.black,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _isAvailable ? "AVAILABLE" : "UNAVAILABLE",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.sp,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 2. Language Badge
                      if (_isAvailable && !_isLoadingIndex)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9D4EDD), Color(0xFF7B2CBF)],
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9D4EDD).withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.translate,
                                size: 12.sp,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _languageInfo.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // 3. HD Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: Colors.white54, width: 1),
                        ),
                        child: Text(
                          "HD",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Title
                  Text(
                    widget.selectedAnime.data.titleEnglish,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          blurRadius: 20.0,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Rating Row
                  Row(
                    children: [
                      _buildStarRating(widget.selectedAnime.data.score),
                      SizedBox(width: 8.w),
                      Text(
                        "${widget.selectedAnime.data.score} / 10",
                        style: TextStyle(
                          color: const Color(0xFFE0AAFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "(${widget.selectedAnime.data.scoredBy} votes)",
                        style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.add, 'My List', () {}),
          _buildActionButton(Icons.share, 'Share', () {
            ShareService.shareAppApk(
              type: ShareType.anime,
              animeTitle: widget.selectedAnime.data.titleEnglish,
              context: context,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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

  Widget _buildMetadataTags() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16.w,
            children: [
              Text(
                widget.selectedAnime.data.year.toString(),
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Container(
                width: 4.w,
                height: 4.w,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                (widget.selectedAnime.data.episodes ?? 0) > 0
                    ? "${widget.selectedAnime.data.episodes} Episodes"
                    : "Ongoing",
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Container(
                width: 4.w,
                height: 4.w,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                widget.selectedAnime.data.duration,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: widget.selectedAnime.data.genres.take(5).map<Widget>((
              genre,
            ) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  genre.name,
                  style: TextStyle(color: Colors.white, fontSize: 12.sp),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    widget.selectedAnime.data.synopsis,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[300], height: 1.5),
                  ),
                  secondChild: Text(
                    widget.selectedAnime.data.synopsis,
                    style: TextStyle(color: Colors.grey[300], height: 1.5),
                  ),
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () => setState(
                    () => _isDescriptionExpanded = !_isDescriptionExpanded,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isDescriptionExpanded ? "Show Less" : "Read More",
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Icon(
                        _isDescriptionExpanded
                            ? Icons.remove_circle_outline
                            : Icons.add_circle_outline,
                        size: 18.sp,
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
    );
  }

  Widget _buildProfessionalDetails() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anime Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          _buildDynamicDetailRow(
            'Studio',
            widget.selectedAnime.data.studios.isNotEmpty
                ? widget.selectedAnime.data.studios.first.name
                : 'N/A',
            Icons.business,
            'Type',
            widget.selectedAnime.data.type,
            Icons.tv,
          ),
          SizedBox(height: 12.h),
          _buildDynamicDetailRow(
            'Status',
            widget.selectedAnime.data.status,
            Icons.calendar_today,
            'Season',
            widget.selectedAnime.data.season.isNotEmpty
                ? widget.selectedAnime.data.season.toUpperCase()
                : 'N/A',
            Icons.layers,
          ),
        ],
      ),
    );
  }

  Widget _buildSponsoredAd() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      height: 100.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple[900]!, Colors.blue[900]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20.w,
            bottom: -20.h,
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 100.sp,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 60.w,
                  height: 60.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.white),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'SPONSORED',
                          style: TextStyle(color: Colors.white, fontSize: 8.sp),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Official Merch Store',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      Text(
                        'Get limited edition figures now!',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        MediaQuery.of(context).padding.bottom + 20.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.grey[900]!)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            offset: Offset(0, -10.h),
            blurRadius: 20.r,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isAvailable
            ? () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                );
              }
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RequestAnimePage()),
                );
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: _isAvailable ? Colors.deepPurple : Colors.grey[800],
          foregroundColor: _isAvailable ? Colors.black : Colors.white54,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isAvailable
                  ? Icons.play_circle_filled
                  : Icons.notifications_active,
              size: 24.sp,
              color: Colors.white,
            ),
            SizedBox(width: 8.w),
            Text(
              _isAvailable
                  ? 'Get S$_currentSelectedSeason Batch 1'
                  : 'Request Anime',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🆕 CONTENT NOT AVAILABLE WIDGET (UPDATED WITH VISIBILITY CHECK)
  // ---------------------------------------------------------------------------
  Widget _buildContentNotAvailableWidget() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 40.sp, color: Colors.grey),
          SizedBox(height: 10.h),
          Text(
            "Content unavailable on current server.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),

          // 🚦 THE BUTTON: Change Server Manually
          // HIDDEN if server connection is stable
          if (_showSwitchButton) ...[
            ElevatedButton.icon(
              onPressed: _handleManualServerSwitch,
              icon: const Icon(Icons.dns, color: Colors.white),
              label: const Text("Change Server / Enter ID"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Check our website for working Server IDs.",
              style: TextStyle(color: Colors.grey[600], fontSize: 10.sp),
            ),
          ] else ...[
            // Alternative Text when button is hidden
            Text(
              "Check back later for updates.",
              style: TextStyle(color: Colors.grey[700], fontSize: 12.sp),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: _buildStickyBottomButton(),
        body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverHeader(),
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(height: 16.h),
              _buildMetadataTags(),
              SizedBox(height: 16.h),
              _buildActionButtons(),
              Divider(color: Colors.white10, height: 32.h),
              _buildDescription(),
              SizedBox(height: 16.h),
              _buildProfessionalDetails(),
              _buildSponsoredAd(),

              // -------------------------------------------------------------
              // 🧠 LOGIC: IF Available -> Show Widget. IF NOT -> Show Error
              // -------------------------------------------------------------
              if (_isAvailable && _foundAnimeData != null)
                AnimeDownloadWidget(
                  animeData: _foundAnimeData!,
                  titleKey: _animeTitleKey!,
                  languageKey: _languageKey,
                  batchKey: _downloadKey,
                  onSeasonChanged: (val) {
                    setState(() => _currentSelectedSeason = val);
                  },
                )
              else if (!_isLoadingIndex)
                // Show Error + Switch Server Button here (If Allowed)
                _buildContentNotAvailableWidget(),

              if (_isAvailable && _foundAnimeData != null)
                _buildTelegramTutorial(),

              SizedBox(height: 70.h),
            ]),
          ),
        ],
      ),
      ),
    );
  }

  @override
  void dispose() {
    SassyAiService.instance.currentAnimeContext = null;
    SassyAiService.instance.isCurrentAnimeAvailable = null;
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildDynamicDetailRow(
    String label1,
    String value1,
    IconData icon1,
    String label2,
    String value2,
    IconData icon2,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth - 12.w;
        double width1;
        double width2;
        if (_expandedDetailLabel == null) {
          width1 = totalWidth * 0.5;
          width2 = totalWidth * 0.5;
        } else if (_expandedDetailLabel == label1) {
          width1 = totalWidth * 0.65;
          width2 = totalWidth * 0.35;
        } else if (_expandedDetailLabel == label2) {
          width1 = totalWidth * 0.35;
          width2 = totalWidth * 0.65;
        } else {
          width1 = totalWidth * 0.5;
          width2 = totalWidth * 0.5;
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildAnimatedCard(label1, value1, icon1, width1),
            _buildAnimatedCard(label2, value2, icon2, width2),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedCard(
    String label,
    String value,
    IconData icon,
    double width,
  ) {
    bool isSelected = _expandedDetailLabel == label;
    return GestureDetector(
      onTap: () => setState(
        () => _expandedDetailLabel = (_expandedDetailLabel == label)
            ? null
            : label,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: width,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
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
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11.sp),
                  ),
                  Text(
                    value,
                    maxLines: isSelected ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🆕 BEAUTIFUL TELEGRAM TUTORIAL SECTION
  // ---------------------------------------------------------------------------
  Widget _buildTelegramTutorial() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 13.w, vertical: 2.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.deepPurple.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.2),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: Colors.amber, size: 28.sp),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  "How to Download Episodes",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "Follow these simple steps to get your episodes directly via Telegram. Don't worry, it's super easy!",
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          _buildTutorialStep(
            stepNumber: "1",
            icon: Icons.list_alt,
            title: "Select your Batch",
            description:
                "Tap on 'Batch 1' (or any batch) above to select the episodes you want to download (e.g., Ep 1-10).",
          ),
          _buildTutorialStep(
            stepNumber: "2",
            icon: Icons.ads_click,
            title: "Click 'Okay, I'll help!'",
            description:
                "A prompt will appear. Simply click the 'Okay, I'll help!' button to proceed.",
          ),
          _buildTutorialStep(
            stepNumber: "3",
            icon: Icons.timer,
            title: "Wait 10 Seconds",
            description:
                "You'll be directed to a sponsor page. It's mandatory to wait there for at least 10 seconds. We appreciate your support!",
          ),
          _buildTutorialStep(
            stepNumber: "4",
            icon: Icons.arrow_back,
            title: "Press the Back Button",
            description:
                "After 10 seconds have passed, just press your device's back button.",
          ),
          _buildTutorialStep(
            stepNumber: "5",
            icon: Icons.telegram,
            title: "Boom! Get Your Files",
            description:
                "You will automatically be redirected to our Telegram bot with all your files ready! Note: If it's your first time, you may need to subscribe to the main OtakuNexa update channel first.",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep({
    required String stepNumber,
    required IconData icon,
    required String title,
    required String description,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: const BoxDecoration(
                  color: Colors.deepPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.w,
                    color: Colors.deepPurple.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: Colors.deepPurpleAccent, size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarClipper extends CustomClipper<Rect> {
  final double fill;
  _StarClipper(this.fill);
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fill, size.height);
  @override
  bool shouldReclip(_StarClipper oldClipper) => oldClipper.fill != fill;
}
