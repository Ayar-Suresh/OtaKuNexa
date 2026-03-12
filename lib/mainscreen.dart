import 'package:flutter/material.dart';
import 'package:otakunexa/pages/Library/community_page.dart';
import 'package:otakunexa/pages/Main/anime_shorts.dart';
import 'package:otakunexa/pages/Main/home_screen.dart';
import 'package:otakunexa/pages/Main/profile_screen.dart';
import 'package:otakunexa/services/api_key_manager.dart';
import 'package:otakunexa/widgets/bottom_navigationbar_widget.dart';

class MainScreen extends StatefulWidget {
  final ApiKeyManager apiManager;
  const MainScreen({super.key, required this.apiManager});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const AnimeShortsPage(),
    const CommunityPage(),
    const AnimeProfilePage(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<bool> _onWillPop() async {
    // If not on Home, go back to previous tab
    if (_selectedIndex != 0) {
      setState(() => _selectedIndex--);
      return false; // don't exit app
    }

    return true; // exit app on back press from home
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: SafeArea(
        top: false,
        child: Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationbarWidget(
            currentIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
          ),
        ),
      ),
    );
  }
}
