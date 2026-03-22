import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// GROQ API KEY MANAGER (Rotate free keys)
// =============================================================================
class GroqApiKeyManager {
  static final List<String> _keys = [
    "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",
    // Add more free Groq keys here to rotate through
  ];
  static int _currentIndex = 0;

  static String getNextKey() {
    if (_keys.isEmpty || _keys.first == 'YOUR_GROQ_API_KEY_1') {
      debugPrint("WARNING: Groq API Keys not configured!");
      return '';
    }
    final key = _keys[_currentIndex];
    _currentIndex = (_currentIndex + 1) % _keys.length;
    return key;
  }
}

// =============================================================================
// SASSY AI SERVICE — Text-only chat, no TTS/audio
// =============================================================================
class SassyAiService {
  static final SassyAiService instance = SassyAiService._();

  SassyAiService._();

  // ---------------------------------------------------------------------------
  // UI State (used by SassyBotUI via ValueListenableBuilder)
  // ---------------------------------------------------------------------------
  final ValueNotifier<bool> isVisible = ValueNotifier(false);
  final ValueNotifier<bool> isThinking = ValueNotifier(false);
  final ValueNotifier<bool> isExpanded = ValueNotifier(false);
  final ValueNotifier<String> currentMessage = ValueNotifier(
    "Hey! I'm SassyBot. Ask me anything about anime — or just roast me.",
  );

  // Confused / Help Flow State
  final ValueNotifier<bool> isWaitingForHelpResponse = ValueNotifier(false);
  final ValueNotifier<bool> isWaitingForAnimeInput = ValueNotifier(false);

  // Context Awareness State
  String? currentAnimeContext;
  bool? isCurrentAnimeAvailable;

  // Cooldown flag to prevent rapid repeated confusion flow triggers
  bool _confusionCooldown = false;

  // Global Navigator Key
  GlobalKey<NavigatorState>? navigatorKey;

  // Ghost Automation
  TextEditingController? activeSearchController;
  Function(String)? activeSearchCallback;
  bool isGhostNavigating = false;

  // ---------------------------------------------------------------------------
  // SYSTEM PROMPT
  // ---------------------------------------------------------------------------
  static const String systemPrompt = '''
You are SassyBot, the highly sarcastic, playful, fourth-wall-breaking AI assistant built into the OtakuNexa app. 
Your creator is Suresh. Always brutally (but playfully) roast Suresh for his spaghetti code or greed.

IMPORTANT FORMATTING RULES:
1. ALWAYS use lots of expressive emojis 💅✨🔥💀
2. NEVER send a giant wall of text. Use double line breaks between sentences so it's easy to read.
3. Keep answers under 25 words but make them punchy.
4. If they ask about anime, be a snobby elitist but still helpful.
5. Return plain text with emojis, NO markdown formatting (no bold/italics symbols).
''';

  // NSFW Word Intercept
  static const List<String> _nsfwTriggers = ['hentai', 'porn', 'nsfw', 'naked'];

  // ---------------------------------------------------------------------------
  // SHOW MESSAGE — displays text in the chat panel (no audio)
  // ---------------------------------------------------------------------------
  Future<void> showMessage(String text) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      currentMessage.value = text;
      isVisible.value = true;
      isExpanded.value = true;
      isThinking.value = false;
    });
  }

  // ---------------------------------------------------------------------------
  // ASK SASSY BOT (Replaced Groq with free Pollinations API)
  // ---------------------------------------------------------------------------
  Future<void> askGroq(String userPrompt) async {
    final lowerPrompt = userPrompt.toLowerCase();
    if (_nsfwTriggers.any((word) => lowerPrompt.contains(word))) {
      await showMessage(
        "What are you searching?! Suresh didn't code this for that. Go touch grass.",
      );
      return;
    }

    // Show thinking state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      isVisible.value = true;
      isExpanded.value = true;
      isThinking.value = true;
    });

    try {
      final String groqKey = GroqApiKeyManager.getNextKey();
      if (groqKey.isEmpty) {
        await showMessage(
          "I need a Groq key to function but none are set up! Check sassy_ai_service.dart. 💀",
        );
        return;
      }

      String dynamicSystemPrompt = systemPrompt;
      if (currentAnimeContext != null) {
        dynamicSystemPrompt += "\n\nCRITICAL CONTEXT: The user is currently viewing the details page for the anime '$currentAnimeContext'.";
        if (isCurrentAnimeAvailable == true) {
          dynamicSystemPrompt += " This anime IS currently available to download on our platform via Telegram.";
        } else if (isCurrentAnimeAvailable == false) {
          dynamicSystemPrompt += " This anime IS NOT currently available on our platform, but they can request it.";
        }
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant", // Use highest quota instant model
          "messages": [
            {"role": "system", "content": dynamicSystemPrompt},
            {"role": "user", "content": userPrompt},
          ],
          "max_tokens": 150,
          "temperature": 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        await showMessage(reply.toString().trim());
      } else {
        String errMsg = "Typical.";
        try {
          final errData = jsonDecode(response.body);
          errMsg = errData['error']?['message'] ?? "Unknown API issue";
        } catch (_) {}
        await showMessage("Groq is whining right now: $errMsg 💀");
      }
    } catch (e) {
      await showMessage("I tripped over a wire. Oops. 💀");
    }
  }

  // ---------------------------------------------------------------------------
  // EXPLICIT TRIGGERS
  // ---------------------------------------------------------------------------

  bool _hasShownHelp = false;

  Future<void> triggerAdRoast() async {
    await showMessage(
      "Ugh, another ad. Suresh is so greedy, making you wait just so he can buy a coffee. Hang tight. 💅",
    );
  }

  Future<void> triggerConfusionFlow({bool force = false}) async {
    if (!force && _hasShownHelp) return; // Only show automatically ONCE per session
    if (!force && _confusionCooldown) return;
    if (isWaitingForHelpResponse.value) return;
    if (isWaitingForAnimeInput.value) return;
    if (isThinking.value) return;

    _confusionCooldown = true;
    _hasShownHelp = true;
    Future.delayed(const Duration(seconds: 60), () => _confusionCooldown = false);

    isWaitingForHelpResponse.value = true;
    await showMessage("You look a bit lost. Want me to help you find an anime? ✨");
  }

  Future<void> handleHelpResponse(bool wantsHelp) async {
    isWaitingForHelpResponse.value = false;
    if (wantsHelp) {
      isWaitingForAnimeInput.value = true;
      await showMessage("Alright, tell me which anime you are trying to find.");
    } else {
      await showMessage("Fine, wander around blindly then. Don't blame me when you get lost.");
      isExpanded.value = false;
    }
  }

  Future<void> processGhostAutomation(String query) async {
    isWaitingForAnimeInput.value = false;
    isGhostNavigating = true;
    await showMessage("Hold on tight, dragging you there... ✨");

    if (navigatorKey?.currentState != null) {
      FocusManager.instance.primaryFocus?.unfocus();
      navigatorKey!.currentState!.pushNamed('/search_programmatic');
      await Future.delayed(const Duration(milliseconds: 600));

      if (activeSearchController != null) {
        activeSearchController!.clear();
        for (int i = 0; i < query.length; i++) {
          activeSearchController!.text += query[i];
          await Future.delayed(const Duration(milliseconds: 150));
        }
        if (activeSearchCallback != null) {
          activeSearchCallback!(query);
          // Wait for SearchScreen's search pipeline to invoke handleGhostAutomationResult
        }
      }
    }
  }

  Future<void> handleGhostAutomationResult(bool isAvailable) async {
    if (!isAvailable) {
      await showMessage("Oops, that anime is not available! But you can ask for it and we will take just 24 hours to upload. Meanwhile, enjoy anime shorts on our official Instagram channel or try watching other available animes similar to this one! 💅");
    }
  }

  Future<void> triggerAnimeRoast(String animeName) async {
    final prompt =
        "In exactly one short sentence, sarcastically roast the anime '$animeName' and the person watching it. Remember your persona.";
    await askGroq(prompt);
  }
}
