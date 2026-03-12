import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyManager {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _prefsKey = 'YOUTUBE_API_KEYS';

  // 1️⃣ Fetch all active keys from Firestore and store locally
  Future<List<String>> fetchAndStoreKeys() async {
    final snapshot = await _firestore
        .collection('apiKeys')
        .where('status', isEqualTo: 'active')
        .get();
    print('📄 Fetched ${snapshot.docs.length} docs from Firestore.');
    final keys = snapshot.docs
        .map((doc) => doc.data()['key'] as String)
        .toList();

    if (keys.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, keys);
      print('Fetched ${keys.length} API keys and stored locally.');
    } else {
      print('No active API keys found in Firebase.');
    }

    return keys;
  }

  // 2️⃣ Get all keys from SharedPreferences
  Future<List<String>> getStoredKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefsKey) ?? [];
  }

  // 3️⃣ Get one key (simple round-robin by index)
  Future<String?> getKey({int index = 0}) async {
    final keys = await getStoredKeys();
    if (keys.isEmpty) return null;
    return keys[index % keys.length];
  }
}
