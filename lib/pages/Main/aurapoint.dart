import 'dart:math';
import 'dart:ui'; // Required for ImageFilter

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otakunexa/pages/Library/req_and_supply.dart';
import 'package:otakunexa/pages/Others/browser_service.dart';
import 'package:otakunexa/services/reward_code_validator.dart'; // Ensure path is correct
import 'package:shared_preferences/shared_preferences.dart';

class AuraPointsCard extends StatefulWidget {
  const AuraPointsCard({super.key});

  @override
  State<AuraPointsCard> createState() => _AuraPointsCardState();
}

class _AuraPointsCardState extends State<AuraPointsCard>
    with TickerProviderStateMixin {
  // --- ANIMATION CONTROLLERS ---
  late AnimationController _rotationCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scaleAnimationController;

  // --- INPUT CONTROLLER ---
  final TextEditingController _codeController = TextEditingController();

  // --- STATE VARIABLES ---
  int currentPoints = 0;
  final int maxPoints = 5;
  bool _isLoading = false;
  String _statusMessage = "ENTER ACCESS KEY";
  Color _statusColor = Colors.white54;
  bool get isAuraMaxed => currentPoints >= maxPoints;

  // --- COLORS ---
  final Color _primaryColor = Colors.deepPurple;
  final Color _accentColor = Colors.amber;

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
      lowerBound: 0.0,
      upperBound: 1.0,
    );

    _loadCurrentPoints();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _glowCtrl.dispose();
    _pulseCtrl.dispose();
    _scaleAnimationController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPoints() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        currentPoints = prefs.getInt('auraCount') ?? 0;
      });
    }
  }

  // --- LOGIC: Validate Code ---
  Future<void> _handleRedeem() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() {
        _statusMessage = "PLEASE PASTE A KEY";
        _statusColor = Colors.redAccent;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = "VERIFYING SIGNATURE...";
      _statusColor = _accentColor;
    });

    final result = await RewardCodeValidator.validateAndRedeemCode(code);

    if (!mounted) return;

    if (result.isValid) {
      final prefs = await SharedPreferences.getInstance();
      int current = prefs.getInt('auraCount') ?? 0;
      int toAdd = result.energy ?? 1;
      int newTotal = current + toAdd;

      if (newTotal > maxPoints) newTotal = maxPoints;

      await prefs.setInt('auraCount', newTotal);

      setState(() {
        currentPoints = newTotal;
        _statusMessage = "ACCEPTED: +$toAdd AURA";
        _statusColor = Colors.greenAccent;
        _isLoading = false;
        _codeController.clear();
      });

      _scaleAnimationController.forward(from: 0.0);
      HapticFeedback.heavyImpact();
    } else {
      setState(() {
        _statusMessage = result.errorMessage?.toUpperCase() ?? "INVALID KEY";
        _statusColor = Colors.redAccent;
        _isLoading = false;
      });
      HapticFeedback.vibrate();
    }
  }

  Future<void> _openGameWebsite() async {
    BrowserService.openUrl(context, "https://minigame.nexa-go.workers.dev");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      height: 420.h, // Fixed height is crucial for Stack inside ScrollView
      child: Stack(
        alignment: Alignment.center,
        children: [
          // --- LAYER 1: Background Pulse ---
          Positioned(
            top: 40.h,
            child: AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                return Container(
                  width: 280.w,
                  height: 280.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(
                          0.15 + (_pulseCtrl.value * 0.1),
                        ),
                        blurRadius: 80.r,
                        spreadRadius: 10.r,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- LAYER 2: The Glass Card Content ---
          Padding(
            padding: EdgeInsets.only(top: 40.h),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: EdgeInsets.fromLTRB(24.w, 60.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // HEADER
                      Text(
                        "AURA RESONANCE",
                        style: TextStyle(
                          color: Colors.white54,
                          letterSpacing: 4,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // BIG NUMBER (Animated)
                      AnimatedBuilder(
                        animation: _scaleAnimationController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale:
                                1.0 + (_scaleAnimationController.value * 0.2),
                            child: Text(
                              "$currentPoints",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 48.sp,
                                fontWeight: FontWeight.w200,
                              ),
                            ),
                          );
                        },
                      ),

                      Text(
                        "Points Collected",
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.sp,
                        ),
                      ),
                      SizedBox(height: 15.h),

                      // PROGRESS BAR
                      _buildAuraProgressBar(),

                      SizedBox(height: 15.h),

                      // STATUS TEXT
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 11.sp,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // INPUT FIELD
                      Container(
                        height: 45.h,
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: TextField(
                          controller: _codeController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 14.sp,
                            letterSpacing: 2,
                          ),
                          decoration: InputDecoration(
                            hintText: "PASTE KEY HERE",
                            hintStyle: TextStyle(
                              color: Colors.white24,
                              fontSize: 12.sp,
                              letterSpacing: 1,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(bottom: 10.h),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // BUTTONS
                      // BUTTONS
                      isAuraMaxed
                          ?
                            // --- CASE 1: Points are MAXED (Show Request Anime) ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RequestAnimePage(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 14.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "Request Anime",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          :
                            // --- CASE 2: Points are NOT MAXED (Show Get Key & Activate) ---
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _openGameWebsite,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white10,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      "GET KEY",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleRedeem,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _accentColor,
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          10.r,
                                        ),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            "ACTIVATE",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.sp,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // --- LAYER 3: The Floating Orb (Top Center) ---
          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: AnimatedBuilder(
                animation: Listenable.merge([_rotationCtrl, _glowCtrl]),
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating Ring
                      Transform.rotate(
                        angle: _rotationCtrl.value * 2 * pi,
                        child: Container(
                          width: 90.w,
                          height: 90.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1.w,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 6.w,
                              height: 6.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accentColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: _accentColor,
                                    blurRadius: 8.r,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Core Circle
                      Container(
                        width: 70.w,
                        height: 70.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(
                                0.5 * _glowCtrl.value,
                              ),
                              blurRadius: 30.r,
                              spreadRadius: 2.r,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuraProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxPoints, (index) {
        bool isActive = index < currentPoints;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30.w,
          height: 4.h,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            color: isActive ? _accentColor : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.6),
                      blurRadius: 6.r,
                    ),
                  ]
                : [],
          ),
        );
      }),
    );
  }
}
