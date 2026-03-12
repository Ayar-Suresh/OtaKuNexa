import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
// Note: We do NOT import url_launcher here to avoid conflicts.

class BrowserService {
  /// Opens a URL in a safe, In-App Chrome Custom Tab.
  static Future<void> openUrl(BuildContext context, String url) async {
    try {
      debugPrint("🚀 Attempting to open In-App Tab for: $url");

      await launchUrl(
        Uri.parse(url),
        customTabsOptions: CustomTabsOptions(
          // 🎨 THEME: Matches OtakuNexa (Black/Purple)
          colorSchemes: CustomTabsColorSchemes.defaults(
            toolbarColor: Colors.black,
            navigationBarColor: Colors.black,
          ),

          // ⚙️ SETTINGS
          shareState: CustomTabsShareState.on,
          urlBarHidingEnabled: true,
          showTitle: true,

          // 🚀 ANIMATIONS: Slide in from right (Native Feel)
          animations: CustomTabsSystemAnimations.slideIn(),

          // ❌ REMOVED: The strict 'browser' block is GONE.
          // ✅ NOW: It auto-detects the best available browser on the device.
        ),

        // 🍎 iOS SAFARI SETTINGS
        safariVCOptions: SafariViewControllerOptions(
          preferredBarTintColor: Colors.black,
          preferredControlTintColor: Colors.deepPurpleAccent,
          barCollapsingEnabled: true,
          dismissButtonStyle: SafariViewControllerDismissButtonStyle.close,
        ),
      );
    } catch (e) {
      // 🛑 If this prints, it means NO browser on the phone supports Custom Tabs
      debugPrint("❌ In-App Browser Failed: $e");
    }
  }
}
