import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SmartSlidingTabs extends StatefulWidget {
  final ValueChanged<int> onChanged;
  final int initialIndex;

  const SmartSlidingTabs({
    super.key,
    required this.onChanged,
    this.initialIndex = 0,
  });

  @override
  State<SmartSlidingTabs> createState() => _SmartSlidingTabsState();
}

class _SmartSlidingTabsState extends State<SmartSlidingTabs> {
  late int _currentIndex;
  // Keys to track the exact position of each tab for accurate scrolling
  late List<GlobalKey> _tabKeys;

  final List<Map<String, dynamic>> tabs = [
    {"name": "Watch Now 🔥 ", "icon": Icons.all_inclusive_rounded},
    {"name": "Anime Guidebook ✨ ", "icon": Icons.auto_awesome_rounded},
    {"name": "Open Seas (YouTube) 📺 ", "icon": Icons.play_circle_fill_rounded},
    {"name": "Shh… It’s Forbidden Anime ⚓ ", "icon": Icons.block},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabKeys = List.generate(tabs.length, (_) => GlobalKey());

    // Scroll to initial index after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    // Logic Fix: Ensure the specific selected widget is visible/centered
    final keyContext = _tabKeys[_currentIndex].currentContext;
    if (keyContext != null) {
      Scrollable.ensureVisible(
        keyContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.5, // 0.5 means center the item in the viewport
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h, // Responsive height
      padding: EdgeInsets.only(top: 13.h),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(), // Better feel on mobile
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
        ), // Add padding start/end
        child: Row(
          children: List.generate(tabs.length, (index) {
            final bool selected = _currentIndex == index;

            return GestureDetector(
              key: _tabKeys[index], // Assign unique key
              onTap: () {
                setState(() => _currentIndex = index);
                widget.onChanged(index);
                // Tiny delay to let the animation start expanding before scrolling
                Future.delayed(
                  const Duration(milliseconds: 50),
                  _scrollToSelected,
                );
              },
              child: Padding(
                padding: EdgeInsets.only(right: 12.w), // Responsive gap
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOut,
                  padding: selected
                      ? EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h)
                      : EdgeInsets.zero,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: selected
                        ? BorderRadius.circular(40.r) // Responsive radius
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circular Icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 35.w, // Responsive width
                        height: 35.w, // Keep it square using .w
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected ? Colors.white : Colors.transparent,
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                            width: 1.2.w, // Responsive border width
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.3),
                                    blurRadius: 8.r, // Responsive blur
                                    spreadRadius: 1.r,
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          tabs[index]["icon"],
                          color: selected ? Colors.black : Colors.white,
                          size: 20.sp, // Responsive icon size
                        ),
                      ),

                      // Label (Expandable)
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        child: selected
                            ? Padding(
                                padding: EdgeInsets.only(
                                  left: 10.w,
                                  right: 8.w,
                                ),
                                child: Text(
                                  tabs[index]["name"],
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.sp, // Responsive font
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
