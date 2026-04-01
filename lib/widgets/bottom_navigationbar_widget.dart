import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomNavigationbarWidget extends StatelessWidget {
  final int currentIndex; // Which tab is selected
  final ValueChanged<int> onItemSelected; // Callback when user taps item

  const BottomNavigationbarWidget({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          height: 65.h + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F).withOpacity(0.65),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.h,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, Icons.home_outlined, 'Home', 0),
              _buildNavItem(Icons.play_circle_filled_sharp, Icons.play_circle_outline_sharp, 'Shorts', 1),
              _buildNavItem(Icons.forum_rounded, Icons.forum_outlined, 'Community', 2),
              _buildNavItem(Icons.account_circle, Icons.account_circle_outlined, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuint,
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon & Glow
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isSelected ? 6.sp : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF9D4EDD).withOpacity(0.4),
                            blurRadius: 10.r,
                            spreadRadius: 2.r,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  isSelected ? activeIcon : inactiveIcon,
                  color: isSelected ? const Color(0xFFE0AAFF) : Colors.white54,
                  size: isSelected ? 24.sp : 22.sp,
                ),
              ),
              SizedBox(height: 3.h),
              
              // Animated Text
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: isSelected ? const Color(0xFFE0AAFF) : Colors.white54,
                  fontSize: isSelected ? 11.5.sp : 10.5.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: isSelected ? 0.5 : 0.0,
                ),
                child: Text(label),
              ),

              // Glowing Underline Indicator
              SizedBox(height: 2.h),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuint,
                height: 3.h,
                width: isSelected ? 20.w : 0,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0AAFF),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE0AAFF).withOpacity(0.8),
                      blurRadius: 4.r,
                      spreadRadius: 1.r,
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
