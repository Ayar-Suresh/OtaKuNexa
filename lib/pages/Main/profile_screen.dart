import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:otakunexa/pages/Library/req_and_supply.dart';
import 'package:otakunexa/pages/Main/aurapoint.dart';
import 'package:otakunexa/pages/Others/about_screen.dart';
import 'package:otakunexa/pages/Others/browser_service.dart';
import 'package:otakunexa/pages/Others/help_screen.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';
import 'package:otakunexa/services/ads_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimeProfilePage extends StatefulWidget {
  const AnimeProfilePage({super.key});

  @override
  _AnimeProfilePageState createState() => _AnimeProfilePageState();
}

class _AnimeProfilePageState extends State<AnimeProfilePage>
    with TickerProviderStateMixin {
  bool isSubscribed = false;
  int auraCount = 0;
  bool hideAds = false;
  bool notificationsEnabled = true;

  late AnimationController _rotationCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scaleAnimationController;

  final Color _backgroundColor = const Color(0xFF000000);
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.amber;
  final Color _textColor = Colors.white;
  final Color _secondaryTextColor = Colors.grey[400]!;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _loadSettings();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      auraCount = prefs.getInt('auraCount') ?? 0;
      hideAds = prefs.getBool('hideAds') ?? false;
      notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      isSubscribed = prefs.getBool('isSubscribed') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auraCount', auraCount);
    await prefs.setBool('hideAds', hideAds);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setBool('isSubscribed', isSubscribed);
  }

  void _watchAdToSupport() {
    // 1. Open the browser
    BrowserService.openUrl(context, "https://minigame.nexa-go.workers.dev");

    // 2. Show the countdown dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental clicks outside
      builder: (context) => AdWaitDialog(
        onComplete: () {
          // 3. ONLY run this if the timer completes successfully
          setState(() {
            auraCount += 1;
            _scaleAnimationController.forward(from: 0.0);
          });
          _saveSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Thanks for supporting! +1 Aura Received ⚡"),
              backgroundColor: Colors.amber,
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  void _showMoreSourcesHint(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierLabel: "hint",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, _, child) {
        final scale = Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return Transform.scale(
          scale: scale.value,
          child: Opacity(
            opacity: animation.value,
            child: Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B1F).withOpacity(0.97),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 16.r,
                      offset: Offset(0, 6.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "✨ Quick Heads-Up!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      "Some videos here are just small preview clips — the ones tagged \"YOUTUBE\".",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                        fontSize: 14.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _buildHintRow(
                      Icons.circle,
                      Colors.amber,
                      "So you seek forbidden treasure? Search or Explore… if you dare.",
                    ),
                    SizedBox(height: 8.h),
                    _buildHintRow(
                      Icons.circle,
                      Colors.cyanAccent,
                      "More sources show up automatically depending on availability.",
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        child: const Text(
                          "All clear!",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHintRow(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 6.h, right: 8.w),
          child: Icon(icon, size: 8.sp, color: color),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildChannelInfoSection()),
          SliverToBoxAdapter(child: SizedBox(height: 30.h)),
          SliverToBoxAdapter(child: AuraPointsCard()),
          SliverToBoxAdapter(child: SizedBox(height: 25.h)),
          SliverToBoxAdapter(child: _buildSuggestionWidget()),
          SliverToBoxAdapter(child: SizedBox(height: 25.h)),
          SliverToBoxAdapter(child: _buildSupportEarnWidget()),
          SliverToBoxAdapter(child: SizedBox(height: 30.h)),
          SliverToBoxAdapter(child: _buildCaptainsStash()),
          SliverToBoxAdapter(child: SizedBox(height: 50.h)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 100.h,
      floating: false,
      pinned: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, color: _textColor, size: 24.sp),
        onPressed: () => Navigator.maybePop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings, color: _textColor, size: 24.sp),
          onPressed: _showSettings,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_primaryColor.withOpacity(0.4), _backgroundColor.withOpacity(0.8)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfoSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAnimatedAvatar(),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OtakuNexa',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '⚓ Latest • Catch',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _secondaryTextColor,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        _buildBadge(
                          '∞',
                          Colors.red,
                          'Treasure',
                          const Color(0xFF1B1B1F),
                        ),
                        SizedBox(width: 8.w),
                        GestureDetector(
                          onTap: () => _showMoreSourcesHint(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'more',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: _primaryColor,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                size: 16.sp,
                                color: _primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.2.w,
              ),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(bottom: 12.h),
                iconColor: _secondaryTextColor,
                collapsedIconColor: _secondaryTextColor,
                title: Text(
                  "⚓ Pirate's Secret Vault — Tap to Unlock",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                children: [
                  Text(
                    "Welcome aboard, traveler. You've just boarded the finest anime ship sailing across the digital seas.\n\nHere, you'll find everything mapped neatly like a treasure chart. Our recommendation system is a legendary compass.\n\nSail responsibly across these digital waves. Even pirates must follow the rules of the sea 😌☠️",
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _secondaryTextColor,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    onPressed: () {
                      _launchPrivacyPolicyUrl(
                        context,
                        "https://www.youtube.com/channel/UCOrY6Ek2DiOZWf7N2sn3A_g",
                      );
                      setState(() => isSubscribed = !isSubscribed);
                      _saveSettings();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubscribed
                          ? Colors.grey[800]
                          : Colors.red,
                      foregroundColor: _textColor,
                      elevation: 2,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isSubscribed) Icon(Icons.check, size: 18.sp),
                        if (isSubscribed) SizedBox(width: 6.w),
                        Text(
                          isSubscribed ? 'SUBSCRIBED' : 'SUBSCRIBE',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _buildCircleBtn(Icons.notifications, () {}),
              SizedBox(width: 8.w),
              _buildCircleBtn(Icons.share_outlined, () {
                ShareService.shareAppApk(
                  type: ShareType.appGlobal,
                  context: context,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(
    String iconText,
    Color iconBg,
    String label,
    Color labelBg,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(6.r),
              bottomLeft: Radius.circular(6.r),
            ),
          ),
          child: Text(
            iconText,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: labelBg,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(6.r),
              bottomRight: Radius.circular(6.r),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: _secondaryTextColor,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.grey[900]!.withOpacity(0.8),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Icon(icon, color: _textColor, size: 20.sp),
      ),
    );
  }

  Widget _buildAnimatedAvatar() {
    return Stack(
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [_primaryColor, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.5),
                blurRadius: 10.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4.w),
            child: Lottie.asset(
              'assets/videos/avatar.json',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.person, color: Colors.white, size: 40.sp),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: _primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: _backgroundColor, width: 2.w),
            ),
            child: Icon(Icons.verified, color: _textColor, size: 14.sp),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.1),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.map_outlined, color: Colors.blueAccent),
        ),
        title: const Text(
          "Navigator's Log",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Got a suggestion? Mark it on the map.",
          style: TextStyle(color: _secondaryTextColor, fontSize: 12.sp),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white54,
          size: 16.sp,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RequestAnimePage()),
        ),
      ),
    );
  }

  Widget _buildSupportEarnWidget() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [Colors.amber.shade700, Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.15),
            blurRadius: 15.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.6),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: _accentColor, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        "CAPTAIN'S BOUNTY",
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Support the Ship & Earn Aura",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "Play our browser mini-game to support us 🎮 Keep it open for 10s to earn your point",
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            ElevatedButton(
              onPressed: _watchAdToSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: EdgeInsets.all(16.w),
                elevation: 5,
              ),
              child: Icon(Icons.play_arrow_rounded, size: 30.sp),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
                border: Border(
                  top: BorderSide(color: _primaryColor.withOpacity(0.3)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _primaryColor.withOpacity(0.1),
                    blurRadius: 20.r,
                    spreadRadius: 5.r,
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(height: 12.h),
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ship Controls",
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: _textColor,
                              size: 18.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 24.h, top: 8.h),
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.15),
                                Colors.deepOrange.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.3),
                              width: 1.w,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.rocket_launch_rounded,
                                color: Colors.amber,
                                size: 24.sp,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Turbo Connection Advised",
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      "We stream from third-party sources. For the best experience, a 5G or high-speed Wi-Fi connection is highly recommended.",
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 12.sp,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildSectionHeader("SYSTEM"),
                        _buildSettingsTile(
                          "Notifications",
                          Icons.notifications_active_outlined,
                          notificationsEnabled,
                          (v) {
                            setModalState(() => notificationsEnabled = v);
                            _saveSettings();
                          },
                        ),
                        SizedBox(height: 24.h),
                        _buildSectionHeader("INFORMATION"),
                        _buildNavTile(
                          "About OtakuNexa",
                          Icons.info_outline,
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => AboutPage()),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildNavTile(
                          "Help & Support",
                          Icons.help_outline,
                          () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HelpPage()),
                          ),
                        ),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          color: _primaryColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNavTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: Colors.white70, size: 20.sp),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white24,
          size: 14.sp,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: _primaryColor, size: 20.sp),
        ),
        title: Text(title, style: TextStyle(color: _textColor)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primaryColor,
          activeTrackColor: _primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildCaptainsStash() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.w, bottom: 12.h, right: 8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on_outlined,
                      color: _accentColor,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      "CAPTAIN'S STASH",
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12.sp,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  "Support is optional and helps with server & development costs.",
                  style: TextStyle(color: _secondaryTextColor, fontSize: 10.sp),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Expanded(
                child: _buildStashCard(
                  title: "Chai Support ☕",
                  subtitle: "₹20 • Optional",
                  icon: Icons.local_cafe_rounded,
                  color: const Color(0xFFFFC107),
                  onTap: () {
                    _launchUpi(
                      context: context,

                      label: "Chai Support for OtakuNexa",
                    );
                  },
                ),
              ),

              SizedBox(width: 12.w),
              Expanded(
                child: _buildStashCard(
                  title: "Fan Support ⭐",
                  subtitle: "₹50 • Helps a lot",
                  icon: Icons.star_rounded,
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    _launchUpi(
                      context: context,

                      label: "Fan Support for OtakuNexa",
                    );
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStashCard(
                  title: "Super Support 🚀",
                  subtitle: "₹100 • Big thanks",
                  icon: Icons.rocket_launch_rounded,
                  color: const Color(0xFF00E5FF),
                  onTap: () {
                    _launchUpi(
                      context: context,

                      label: "Super Support for OtakuNexa",
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStashCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 76.h, // ⬅️ slightly taller
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 15.r,
              offset: Offset(0, 4.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
            SizedBox(width: 8.w),
            Expanded(
              // ⬅️ VERY IMPORTANT
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 11.sp,
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
}

Future<void> _launchPrivacyPolicyUrl(BuildContext context, String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

Future<void> _launchUpi({
  required BuildContext context,
  required String label, // e.g. "Buy me an Onigiri 🍙"
}) async {
  const String upiId = "otakunexa@upi"; // 🔴 Replace with YOUR UPI ID

  // 📏 MediaQuery: Get screen width to calculate dynamic dialog width
  final double screenWidth = MediaQuery.of(context).size.width;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 📏 MediaQuery: Ensure dialog is 85% of screen width
        insetPadding: EdgeInsets.symmetric(horizontal: (screenWidth * 0.05)),
        child: Container(
          decoration: BoxDecoration(
            // ✨ Gradient Background
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A1A), // Dark Grey
                const Color(0xFF4A148C), // Deep Purple (Otaku Theme)
              ],
            ),
            borderRadius: BorderRadius.circular(24.r), // Responsive Radius
            border: Border.all(color: Colors.white12, width: 1.w),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20.r,
                spreadRadius: 2.r,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✨ 1. Gratitude Icon (Responsive)
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: Colors.purpleAccent,
                  size: 32.sp, // Responsive Icon Size
                ),
              ),
              SizedBox(height: 16.h),

              // ✨ 2. Title & Subtitle
              Text(
                "Arigato Gozaimasu! 🙏",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp, // Responsive Font
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                "Your support fuels the OtakuNexa engine.",
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),

              // ✨ 3. The "Badge" (What they are buying)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.purpleAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  label, // e.g. "Buy me an Onigiri 🍙"
                  style: TextStyle(
                    color: Colors.purpleAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.h),

              // ✨ 4. QR Code Section
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purpleAccent.withOpacity(0.2),
                      blurRadius: 15.r,
                      spreadRadius: 1.r,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.asset(
                    'assets/logo/qrcode.jpeg',
                    height: 180.h, // Responsive Height
                    width: 180.h, // Keep it square
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Scan to Pay",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10.sp,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 24.h),

              // ✨ 5. Copy UPI Section
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "UPI ID",
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 10.sp,
                            ),
                          ),
                          Text(
                            upiId,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Copy Button
                    Material(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(8.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: upiId));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20.sp,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    "UPI ID Copied! Thank you! ❤️",
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          child: Text(
                            "Copy",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Close Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: EdgeInsets.all(8.w),
                  child: Text(
                    "Maybe Later",
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
