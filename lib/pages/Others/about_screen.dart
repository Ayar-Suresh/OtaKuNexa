import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = "";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = info.version;
    });
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Colors.deepPurpleAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
        title: Text(
          "About",
          style: TextStyle(color: Colors.white, fontSize: 20.sp),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 24.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w), // Responsive padding
        child: Column(
          children: [
            //Lottie Animation
            SizedBox(
              height: 150.h, // Responsive height
              child: Lottie.asset('assets/videos/avatar.json'),
            ),
            SizedBox(height: 12.h),

            // App Name
            Text(
              "OtakuNexa",
              style: TextStyle(
                fontSize: 28.sp, // Responsive font
                fontWeight: FontWeight.bold,
                color: accentColor,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: accentColor.withOpacity(0.8),
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),

            // Tagline
            SizedBox(height: 4.h),
            Text(
              "Your Gateway to Unlimited Anime Adventures",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            // About Text
            Text(
              "OtakuNexa is your ultimate anime streaming companion, bringing you the latest episodes, trending series, and timeless classics — all in one place. "
              "With a sleek interface and smooth playback, we’re here to make your anime journey seamless and enjoyable.",
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white70,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 20.h),

            // Features Row
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFeatureIcon(
                    Icons.play_circle_fill,
                    "HD Streaming",
                    accentColor,
                  ),
                  _buildFeatureIcon(
                    Icons.update,
                    "Latest Episodes",
                    accentColor,
                  ),
                  _buildFeatureIcon(
                    Icons.favorite,
                    "Curated Picks",
                    accentColor,
                  ),
                ],
              ),
            ),

            SizedBox(height: 30.h),

            // Developer Credit
            Text(
              "Developed by 🤫",
              style: TextStyle(color: Colors.white54, fontSize: 14.sp),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 5.h),

            // App Version
            Text(
              "Version: $_appVersion",
              style: TextStyle(color: Colors.white38, fontSize: 12.sp),
            ),

            SizedBox(height: 20.h),

            // Social Media Handles
            Container(
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                "Follow Us",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 10.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(Icons.telegram, "https://t.me/OtakuNexa"),
                SizedBox(width: 15.w),
                _socialIcon(
                  Icons.video_library,
                  "https://www.youtube.com/@OtaKuNexa_official",
                ),
                SizedBox(width: 15.w),
                _socialIcon(
                  Icons.camera_alt,
                  "https://www.instagram.com/otakunexa_official",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32.sp),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 12.sp),
        ),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E1E1E).withOpacity(0.5),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurpleAccent.withOpacity(0.2),
              blurRadius: 10.r,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 20.sp),
      ),
    );
  }
}
