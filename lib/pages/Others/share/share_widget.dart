import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/pages/Others/share/share_service.dart';

class OtakuShareButton extends StatelessWidget {
  final ShareType type;
  final String? animeTitle;
  final bool isCompact; // Small circular button
  final bool isFloating; // Floating Action Button style

  const OtakuShareButton({
    super.key,
    required this.type,
    this.animeTitle,
    this.isCompact = false,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Floating Style (For Shorts/Home)
    if (isFloating) {
      return FloatingActionButton(
        onPressed: () => ShareService.shareAppApk(
          type: type,
          animeTitle: animeTitle,
          context: context,
        ),
        backgroundColor: const Color(0xFF9D4EDD),
        elevation: 10,
        child: const Icon(Icons.share_rounded, color: Colors.white),
      );
    }

    // 2. Compact Style (For Detail Pages/Headers)
    if (isCompact) {
      return IconButton(
        onPressed: () => ShareService.shareAppApk(
          type: type,
          animeTitle: animeTitle,
          context: context,
        ),
        icon: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Icon(Icons.share_rounded, color: Colors.white, size: 20.sp),
        ),
      );
    }

    // 3. Default "Amazing" Full Width Button
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2CBF), Color(0xFF9D4EDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9D4EDD).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => ShareService.shareAppApk(
          type: type,
          animeTitle: animeTitle,
          context: context,
        ),
        icon: const Icon(Icons.send_rounded, color: Colors.white),
        label: Text(
          _getButtonLabel(),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  String _getButtonLabel() {
    switch (type) {
      case ShareType.shorts:
        return "Share App (Shorts)";
      case ShareType.anime:
        return "Send APK to Friend";
      default:
        return "Share App File Directly";
    }
  }
}
