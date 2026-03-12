import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart'; // 📦 Add this package if missing
import 'package:share_plus/share_plus.dart';

enum ShareType { appGlobal, shorts, anime }

class ShareService {
  static const MethodChannel _platform = MethodChannel(
    'com.watch.otakunexa/share',
  );

  // 🔗 The official download link
  static const String _downloadLink = "https://otakunexa.nexa-go.workers.dev/";

  static Future<void> shareAppApk({
    required ShareType type,
    String? animeTitle,
    BuildContext? context,
  }) async {
    try {
      // 1. Get the original System Path of the APK
      final String systemApkPath = await _platform.invokeMethod('getApkPath');
      final File originalFile = File(systemApkPath);

      // 2. Prepare a Safe Copy in the Temporary Cache Directory
      final Directory tempDir = await getTemporaryDirectory();
      final String safePath = '${tempDir.path}/OtakuNexa_App.apk';

      // Copy the file (Overwrites if exists, ensures fresh copy)
      final File safeFile = await originalFile.copy(safePath);

      // 3. Define Message based on Context
      String message = "";
      String subject = "";

      switch (type) {
        case ShareType.shorts:
          message =
              "🔥 Watch amazing Anime Shorts and Connect with the Anime Community on OtakuNexa! Minimal Ads, Pure Focus.\n\n"
              "Install this APK directly or download from the link below 👇\n\n"
              "🔗 $_downloadLink";
          subject = "Check out OtakuNexa Shorts & Community";
          break;

        case ShareType.anime:
          message =
              "🎬 I'm watching ${animeTitle ?? 'Anime'} on OtakuNexa.\n\n"
              "Here is the App APK file. You can also download it from here 👇\n\n"
              "🔗 $_downloadLink";
          subject = "Watch ${animeTitle ?? 'Anime'} on OtakuNexa";
          break;

        case ShareType.appGlobal:
        default:
          message = '''🎌 OtakuNexa – The Ultimate Anime Hub

🔥 Stream & download anime
⚡ Shorts & spotlight recommendations
📚 Curated collections for Indian otakus
🎨 Clean & smooth UI

Download & join the OtakuNexa community via the APK or Link below 👇

🔗 $_downloadLink''';
          subject = "Install OtakuNexa";
          break;
      }

      // 4. Share the SAFE COPY + Message with Link
      await Share.shareXFiles(
        [XFile(safeFile.path)],
        text: message,
        subject: subject,
      );
    } catch (e) {
      print("⚠️ Error sharing APK: $e");

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not prepare APK for sharing.")),
        );
      }
    }
  }
}
