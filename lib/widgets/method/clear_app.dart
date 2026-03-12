import 'package:flutter/services.dart';

class AppSettingsHelper {
  static const _platform = MethodChannel('app.settings/cache_clear');

  static Future<void> openAppInfo() async {
    try {
      await _platform.invokeMethod('openAppInfo');
    } on PlatformException catch (e) {
      print("Error opening App Info: ${e.message}");
    }
  }
}
