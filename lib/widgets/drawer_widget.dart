import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Added ScreenUtil
import 'package:lottie/lottie.dart';
import 'package:otakunexa/pages/Library/community_page.dart';
import 'package:otakunexa/pages/Library/req_and_supply.dart';
import 'package:otakunexa/pages/Main/anime_shorts.dart';
import 'package:otakunexa/pages/Main/home_screen.dart';
import 'package:otakunexa/pages/Main/profile_screen.dart';
import 'package:otakunexa/pages/Others/about_screen.dart';
import 'package:otakunexa/pages/Others/help_screen.dart';

class CustomDrawer extends StatelessWidget {
  final String selectedPage;

  const CustomDrawer({super.key, required this.selectedPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0E0E0E),
      child: Column(
        children: [
          // Animated Gradient Header
          SafeArea(
            child: Container(
              width: double.infinity,
              // Responsive padding
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 32.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF9D4EDD), Color(0xFF5A189A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Avatar with glow border
                  Container(
                    padding: EdgeInsets.all(4.w), // Responsive padding
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.6),
                          blurRadius: 12.r, // Responsive blur
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                    child: SizedBox(
                      height: 70.h, // Responsive height
                      child: Lottie.asset('assets/videos/avatar.json'),
                    ),
                  ),
                  SizedBox(height: 12.h), // Responsive spacing
                  Text(
                    "Welcome, To Otaku!",
                    style: TextStyle(
                      fontSize: 22.sp, // Responsive font
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Explore the anime universe",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14.sp, // Responsive font
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                vertical: 8.h,
              ), // Responsive padding
              children: [
                _buildDrawerSectionTitle("Main"),
                _buildDrawerItem(
                  context,
                  Icons.home,
                  "Home",
                  selectedPage == "Home",
                  const HomeScreen(),
                ),
                _buildDrawerItem(
                  context,
                  Icons.trending_up,
                  "Shorts",
                  selectedPage == "Shorts",
                  const AnimeShortsPage(),
                ),

                _buildDrawerSectionTitle("Community"),

                _buildDrawerItem(
                  context,
                  Icons.forum_outlined,
                  "Community",
                  selectedPage == "Community",
                  CommunityPage(),
                ),
                _buildDrawerItem(
                  context,
                  Icons.sensors,
                  "Request & Supply",
                  selectedPage == "Request & Supply",
                  RequestAnimePage(),
                ),

                _buildDrawerSectionTitle("Settings"),
                _buildDrawerItem(
                  context,
                  Icons.settings,
                  "Settings",
                  selectedPage == "Settings",
                  AnimeProfilePage(),
                ),
                _buildDrawerItem(
                  context,
                  Icons.help_outline,
                  "Help",
                  selectedPage == "Help",
                  const HelpPage(),
                ),
                _buildDrawerItem(
                  context,
                  Icons.info_outline,
                  "About",
                  selectedPage == "About",
                  const AboutPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Title
  Widget _buildDrawerSectionTitle(String title) {
    return Padding(
      // Responsive padding
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 0, 6.h),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 13.sp, // Responsive font
          letterSpacing: 1,
        ),
      ),
    );
  }

  // Drawer Item
  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String title,
    bool isSelected, [
    Widget? page,
  ]) {
    return Container(
      // Responsive margin
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.deepPurple.withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14.r), // Responsive radius
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w), // Responsive padding
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isSelected
                  ? [Colors.pinkAccent, Colors.deepPurpleAccent]
                  : [Colors.white10, Colors.white10],
            ),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 24.sp, // Responsive icon size
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14.sp, // Responsive font size
          ),
        ),
        onTap: () {
          if (page != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          }
        },
      ),
    );
  }
}
