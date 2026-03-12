import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added ScreenUtil

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
    // Smartly calculate height: 60h + the device's bottom padding (safe area)
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      // Dynamic height to accommodate safe area
      height: 60.h + bottomPadding,
      // Push content up by the amount of bottom padding
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF2A2A2A),
            width: 1.h, // Responsive border width
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.play_circle_outline_sharp, 'Shorts', 1),
          _buildNavItem(Icons.forum_outlined, 'Community', 2),
          _buildNavItem(Icons.account_circle_outlined, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = index == currentIndex;

    return Expanded(
      child: InkWell(
        onTap: () => onItemSelected(index),
        splashColor: Colors.deepPurple.withOpacity(0.3),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h), // Responsive padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF9D4EDD) : Colors.white60,
                size: 22.sp, // Scalable pixel size for icon
              ),
              SizedBox(height: 3.h), // Responsive spacing
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF9D4EDD) : Colors.white60,
                  fontSize: 11.5.sp, // Scalable pixel size for text
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
