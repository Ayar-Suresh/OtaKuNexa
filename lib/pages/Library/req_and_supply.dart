import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
// Ensure this import path is correct for your project structure
import 'package:otakunexa/pages/Others/browser_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RequestAnimePage extends StatefulWidget {
  const RequestAnimePage({super.key});

  @override
  State<RequestAnimePage> createState() => _RequestAnimePageState();
}

// Added WidgetsBindingObserver to detect app background/foreground state
class _RequestAnimePageState extends State<RequestAnimePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // --- DISCORD CONFIGURATION ---
  final String _requestWebhook =
      'https://discord.com/api/webhooks/1451113558967324744/-uyBaYfKHBxqx5KvFdtWoeQ5xoL2MKNQygAsFkaf0Zwqpnz6dQv9XUsyidO6Fqt8kADN';
  final String _supplyWebhook =
      'https://discord.com/api/webhooks/1451115131445710868/qmB0OlKlkzTl5ImQIVsvwioEP5jUVsu-jkgWA6TDY9_ZpQnqwxzNe7Mh-sgzJRkhla0X';

  // --- CONTROLLERS & KEYS ---
  late TabController _tabController;
  final _reqFormKey = GlobalKey<FormState>();
  final _linkFormKey = GlobalKey<FormState>();

  final TextEditingController _reqTitleController = TextEditingController();
  final TextEditingController _reqDescController = TextEditingController();
  final TextEditingController _supplyTitleController = TextEditingController();
  final TextEditingController _supplyDescController = TextEditingController();

  final List<LinkCollection> _linkCollections = [];

  // --- AURA & AD SETTINGS ---
  int _auraCount = 0;
  final int _maxAura = 5;
  final int _requestCost = 5;
  final int _adReward = 1;

  // AD LOGIC CONFIG
  final int _adDurationSeconds = 10; // Required time to stay away
  bool _isLoading = false;
  bool _isWatchingAd = false; // Flag to check if ad process is active
  DateTime? _adStartTime; // Tracks when they clicked the button

  String _selectedType = 'Series';
  final List<String> _languages = [];
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Register the observer to listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: 2, vsync: this);
    _loadAura();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _addCollection();
  }

  @override
  void dispose() {
    // Remove the observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);

    _tabController.dispose();
    _pulseController.dispose();
    _reqTitleController.dispose();
    _reqDescController.dispose();
    _supplyTitleController.dispose();
    _supplyDescController.dispose();
    super.dispose();
  }

  // --- APP LIFECYCLE LISTENER ( The Core Logic ) ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // We only care if the app is RESUMED (User came back)
    // AND they were currently in the "Watching Ad" state
    if (state == AppLifecycleState.resumed &&
        _isWatchingAd &&
        _adStartTime != null) {
      _verifyAdDuration();
    }
  }

  void _verifyAdDuration() async {
    final DateTime now = DateTime.now();
    final int difference = now.difference(_adStartTime!).inSeconds;

    // Reset the flag so this only triggers once per click
    setState(() {
      _isWatchingAd = false;
      _adStartTime = null;
    });

    if (difference >= _adDurationSeconds) {
      // SUCCESS: They stayed away long enough
      await _updateAura(_adReward);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Text("+1 Aura Recovered!", style: TextStyle(fontSize: 14.sp)),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      // FAILURE: They came back too fast
      int remaining = _adDurationSeconds - difference;
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(
              "Ad Interrupted",
              style: TextStyle(color: Colors.redAccent, fontSize: 18.sp),
            ),
            content: Text(
              "You returned too early!\n\nYou must stay on the page for at least 10 seconds to recharge energy.\n\nTime remaining was: ${remaining}s",
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Understood",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  // --- AURA MANAGEMENT ---
  Future<void> _loadAura() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _auraCount = (prefs.getInt('auraCount') ?? 0).clamp(0, _maxAura);
    });
  }

  Future<void> _updateAura(int change) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _auraCount = (_auraCount + change).clamp(0, _maxAura);
      prefs.setInt('auraCount', _auraCount);
    });
  }

  // --- WATCH AD ACTION ---
  Future<void> _watchAd() async {
    if (_auraCount >= _maxAura) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Aura is already at maximum capacity!",
            style: TextStyle(fontSize: 14.sp),
          ),
        ),
      );
      return;
    }

    // 1. Set flags
    setState(() {
      _isWatchingAd = true;
      _adStartTime = DateTime.now();
    });

    // 2. Open Browser
    BrowserService.openUrl(
      context,
      "https://www.effectivegatecpm.com/j7w9ucfu?key=702b3a8a2b0287aec2efeb78306a5d1e",
    );

    // 3. Logic pauses here until user returns (handled by didChangeAppLifecycleState)
  }

  // --- DISCORD BACKEND ---
  Future<void> _sendToDiscord({
    required String webhookUrl,
    required String embedTitle,
    required List<Map<String, dynamic>> fields,
    required Color color,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": "Anime Nexus Scout",
          "embeds": [
            {
              "title": embedTitle,
              "color": color.value & 0xFFFFFF,
              "fields": fields,
              "timestamp": DateTime.now().toIso8601String(),
              "footer": {"text": "System Link Established"},
            },
          ],
        }),
      );
      if (response.statusCode != 204) {
        debugPrint("Discord Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Network Error: $e");
    }
  }

  void _submitRequest() async {
    if (!_reqFormKey.currentState!.validate()) return;
    if (_auraCount < _requestCost) {
      _showLowAuraDialog();
      return;
    }

    setState(() => _isLoading = true);

    await _sendToDiscord(
      webhookUrl: _requestWebhook,
      embedTitle: "📡 NEW ANIME SIGNAL RECEIVED",
      color: const Color(0xFF9D4EDD),
      fields: [
        {
          "name": "Anime Title",
          "value": _reqTitleController.text,
          "inline": true,
        },
        {"name": "Format", "value": _selectedType, "inline": true},
        {
          "name": "Audio Prefs",
          "value": _languages.isEmpty ? "Any" : _languages.join(", "),
          "inline": true,
        },
        {
          "name": "Description",
          "value": _reqDescController.text,
          "inline": false,
        },
      ],
    );

    await _updateAura(-_requestCost);
    setState(() => _isLoading = false);

    if (mounted) _showSuccessDialog("Request Sent");
  }

  void _submitSupplyDrop() async {
    if (!_linkFormKey.currentState!.validate()) return;
    bool hasLinks = _linkCollections.any((c) => c.links.isNotEmpty);
    if (!hasLinks) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please add at least one link!",
            style: TextStyle(fontSize: 14.sp),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    String payloadText = "";
    for (var col in _linkCollections) {
      payloadText += "\n📂 **${col.title}**\n";
      for (var link in col.links) {
        payloadText += "• ${link.label}: <${link.url}>\n";
      }
    }

    await _sendToDiscord(
      webhookUrl: _supplyWebhook,
      embedTitle: "📦 NEW SUPPLY DROP ARRIVED",
      color: const Color(0xFF00E676),
      fields: [
        {"name": "Anime", "value": _supplyTitleController.text, "inline": true},
        {
          "name": "Notes",
          "value": _supplyDescController.text.isEmpty
              ? "No notes"
              : _supplyDescController.text,
          "inline": true,
        },
        {"name": "Payload", "value": payloadText, "inline": false},
      ],
    );

    setState(() => _isLoading = false);

    if (mounted) _showSuccessDialog("Supply Received");
  }

  // --- UI BUILDER ---
  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: const Size(360, 800));

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: Stack(
        children: [
          // Background Gradient Circle
          Positioned(
            top: -100.h,
            right: -100.w,
            child: Container(
              height: 400.h,
              width: 400.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7B2CBF).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Scroll View
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  "Request & Supply",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                centerTitle: true,
                actions: [
                  _buildAuraBadge(),
                  SizedBox(width: 16.w),
                ],
              ),
            ],
            body: Column(
              children: [
                SizedBox(height: 10.h),
                _buildCustomTabs(),
                SizedBox(height: 20.h),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_buildRequestForm(), _buildSupplyForm()],
                  ),
                ),
              ],
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: const Color(0xFF9D4EDD),
                      strokeWidth: 4.w,
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      "Establishing Uplink...",
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  void _addCollection() {
    setState(() {
      _linkCollections.add(LinkCollection());
    });
  }

  void _showLowAuraDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(
          "Insufficient Aura",
          style: TextStyle(color: Colors.redAccent, fontSize: 18.sp),
        ),
        content: Text(
          "You need full energy (5 Aura) to send this request.",
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(fontSize: 14.sp)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _watchAd();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: Text(
              "Watch Ad",
              style: TextStyle(color: Colors.black, fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: const Color(0xFF10002B),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFF9D4EDD), width: 2.w),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9D4EDD).withOpacity(0.5),
                blurRadius: 20.r,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.greenAccent, size: 60.sp),
              SizedBox(height: 16.h),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                "Our scouts have received your transmission.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9D4EDD),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 10.h,
                  ),
                ),
                child: Text(
                  "Return to Base",
                  style: TextStyle(color: Colors.white, fontSize: 14.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      height: 55.h,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _tabController.animation!,
            builder: (context, child) {
              final double offset =
                  _tabController.offset + _tabController.index;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth * 0.5;
                  return Transform.translate(
                    offset: Offset(offset * width, 0),
                    child: Container(
                      width: width,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF9D4EDD), Color(0xFFE0AAFF)],
                        ),
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Row(
            children: [
              _buildTabItem(0, "Request Signal", Icons.radar),
              _buildTabItem(1, "Supply Drop", Icons.paragliding),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String label, IconData icon) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          HapticFeedback.lightImpact();
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                final double selectedValue = _tabController.animation!.value;
                final bool isSelected =
                    (index == 0 && selectedValue < 0.5) ||
                    (index == 1 && selectedValue >= 0.5);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: isSelected ? Colors.white : Colors.grey,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestForm() {
    bool canAfford = _auraCount >= _requestCost;
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _reqFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("TARGET INTEL"),
            _buildNeonTextField(
              controller: _reqTitleController,
              label: "Anime Title",
              icon: Icons.movie_filter_outlined,
              mandatory: true,
            ),
            SizedBox(height: 16.h),
            _buildNeonTextField(
              controller: _reqDescController,
              label: "Description / Notes",
              icon: Icons.notes,
              mandatory: true,
              maxLines: 3,
            ),
            SizedBox(height: 30.h),
            _buildSectionLabel("PREFERENCES"),
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  _buildDropdownRow(
                    "Format",
                    ["Series", "Movie", "OVA"],
                    _selectedType,
                    (val) => setState(() => _selectedType = val!),
                  ),
                  Divider(color: Colors.white10, height: 30.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Audio Preference",
                      style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: ["Sub", "Dub", "Hindi Dub"].map((lang) {
                      bool isSelected = _languages.contains(lang);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(lang),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _languages.add(lang)
                              : _languages.remove(lang),
                        ),
                        backgroundColor: Colors.black,
                        selectedColor: const Color(0xFF9D4EDD),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey,
                          fontSize: 12.sp,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),
            if (_auraCount < _requestCost) ...[
              _buildRechargeStation(),
              SizedBox(height: 20.h),
            ],
            _buildSubmitButton(
              "TRANSMIT REQUEST",
              canAfford,
              _submitRequest,
              _requestCost,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplyForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _linkFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel("ASSET DETAILS"),
            _buildNeonTextField(
              controller: _supplyTitleController,
              label: "Anime Title",
              icon: Icons.video_library,
              mandatory: true,
            ),
            SizedBox(height: 16.h),
            _buildNeonTextField(
              controller: _supplyDescController,
              label: "Quality / Source Notes",
              icon: Icons.info_outline,
              maxLines: 2,
            ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionLabel("LINK PAYLOAD"),
                IconButton(
                  onPressed: _addCollection,
                  icon: Icon(
                    Icons.add_circle,
                    color: const Color(0xFF9D4EDD),
                    size: 24.sp,
                  ),
                ),
              ],
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _linkCollections.length,
              separatorBuilder: (_, __) => SizedBox(height: 16.h),
              itemBuilder: (context, index) => _buildLinkCollectionCard(index),
            ),
            SizedBox(height: 40.h),
            _buildSubmitButton("UPLOAD SUPPLIES", true, _submitSupplyDrop, 0),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRechargeStation() {
    bool isMaxed = _auraCount >= _maxAura;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isMaxed
                ? Colors.white.withOpacity(0.05)
                : Colors.amber.withOpacity(0.1),
            Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMaxed ? Colors.white10 : Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: isMaxed
                  ? Colors.grey.withOpacity(0.2)
                  : Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isMaxed ? Icons.battery_full : Icons.play_circle_fill,
              color: isMaxed ? Colors.grey : Colors.amber,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMaxed ? "Energy Full" : "Low Energy",
                  style: TextStyle(
                    color: isMaxed ? Colors.grey : Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  isMaxed
                      ? "Aura is at maximum (5/5)"
                      : "Stay 10s on ad to recover (+1 Aura)",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isMaxed ? null : _watchAd,
            child: Text(
              isMaxed ? "MAXED" : "WATCH",
              style: TextStyle(
                color: isMaxed ? Colors.grey : Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkCollectionCard(int index) {
    final collection = _linkCollections[index];
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF151517),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: collection.title,
                  onChanged: (val) => collection.title = val,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: "Season Name",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.folder_open,
                      color: Colors.amber,
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
              if (_linkCollections.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20.sp,
                  ),
                  onPressed: () =>
                      setState(() => _linkCollections.removeAt(index)),
                ),
            ],
          ),
          Divider(color: Colors.white10, height: 16.h),
          ...collection.links.asMap().entries.map((entry) {
            int linkIndex = entry.key;
            LinkItem link = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 80.w,
                    child: TextFormField(
                      initialValue: link.label,
                      onChanged: (val) => link.label = val,
                      style: TextStyle(color: Colors.white, fontSize: 13.sp),
                      decoration: InputDecoration(
                        hintText: "Ep 1",
                        hintStyle: TextStyle(fontSize: 13.sp),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: TextFormField(
                        initialValue: link.url,
                        onChanged: (val) => link.url = val,
                        style: TextStyle(
                          color: const Color(0xFF9D4EDD),
                          fontSize: 13.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: "https://...",
                          hintStyle: TextStyle(fontSize: 13.sp),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey, size: 16.sp),
                    onPressed: () =>
                        setState(() => collection.links.removeAt(linkIndex)),
                  ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => collection.links.add(LinkItem())),
            icon: Icon(Icons.add_link, size: 16.sp, color: Colors.white70),
            label: Text(
              "Add Link",
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 4.w),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF9D4EDD),
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildNeonTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool mandatory = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: Colors.white, fontSize: 14.sp),
      validator: mandatory
          ? (val) => val == null || val.isEmpty ? "Required field" : null
          : null,
      decoration: InputDecoration(
        labelText: mandatory ? "$label *" : label,
        labelStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        prefixIcon: Icon(icon, color: const Color(0xFF9D4EDD), size: 20.sp),
        filled: true,
        fillColor: const Color(0xFF121212),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xFF9D4EDD), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdownRow(
    String label,
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF1A1A1A),
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              icon: Icon(Icons.arrow_drop_down, size: 24.sp),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    String label,
    bool isEnabled,
    VoidCallback onPressed,
    int cost,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9D4EDD),
          disabledBackgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEnabled ? Icons.rocket_launch : Icons.lock,
              color: isEnabled ? Colors.white : Colors.grey,
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Text(
              isEnabled
                  ? (cost > 0 ? "$label (-$cost)" : label)
                  : "NEED $cost AURA",
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuraBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Icon(
              Icons.bolt,
              color: Colors.amber.withOpacity(
                0.8 + (_pulseController.value * 0.2),
              ),
              size: 18.sp,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            "$_auraCount / $_maxAura",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// --- DATA CLASSES ---
class LinkCollection {
  String title;
  List<LinkItem> links;
  LinkCollection({this.title = "Season 1", List<LinkItem>? links})
    : links = links ?? [LinkItem()];
}

class LinkItem {
  String label;
  String url;
  LinkItem({this.label = "", this.url = ""});
}
