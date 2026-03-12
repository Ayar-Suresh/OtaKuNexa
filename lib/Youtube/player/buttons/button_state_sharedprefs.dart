import 'package:otakunexa/youtube/player/buttons/button_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActionPrefs {
  static const String smashedKey = "smashed";
  static const String trashedKey = "trashed";

  static const String savedKey = "saved";

  static Future<void> saveState(ActionState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(smashedKey, state.smashed);
    await prefs.setBool(trashedKey, state.trashed);

    await prefs.setBool(savedKey, state.saved);
  }

  static Future<ActionState> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    return ActionState(
      smashed: prefs.getBool(smashedKey) ?? false,
      trashed: prefs.getBool(trashedKey) ?? false,

      saved: prefs.getBool(savedKey) ?? false,
    );
  }
}
