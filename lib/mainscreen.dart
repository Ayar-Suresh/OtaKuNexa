import 'package:flutter/material.dart';
import 'package:otakunexa/pages/Library/community_page.dart';
import 'package:otakunexa/pages/Main/anime_shorts.dart';
import 'package:otakunexa/pages/Main/home_screen.dart';
import 'package:otakunexa/pages/Main/profile_screen.dart';
import 'dart:async';
import 'package:otakunexa/services/api_key_manager.dart';
import 'package:otakunexa/widgets/bottom_navigationbar_widget.dart';
import 'package:otakunexa/services/sassy_ai_service.dart';

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

  Timer? _idleTimer;
  int _tapCount = 0;
  Timer? _tapResetTimer;

  @override
  void initState() {
    super.initState();
    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    // Trigger confusion flow after 60 seconds of idle (up from 45 to be less aggressive)
    _idleTimer = Timer(const Duration(seconds: 60), () {
      SassyAiService.instance.triggerConfusionFlow();
    });
  }

  void _handleUserInteraction(PointerEvent details) {
    _resetIdleTimer();
    _tapCount++;
    // Only trigger rapid-tap confusion flow if user is tapping frantically (10+ taps)
    // and the bot is not already active
    if (_tapCount >= 10) {
      SassyAiService.instance.triggerConfusionFlow();
      _tapCount = 0;
    }
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(seconds: 3), () {
      _tapCount = 0;
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _tapResetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Listener(
        onPointerDown: _handleUserInteraction,
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
      ),
    );
  }
}
