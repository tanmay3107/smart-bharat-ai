import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TextToSpeechService {
  static final FlutterTts _tts = FlutterTts();

  static Future<void> speak(String text, String languageCode) async {
    if (text.isEmpty) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
      double speechRate = prefs.getDouble('speechRate') ?? 0.5;

      if (ttsEnabled) {
        await _tts.setLanguage(_getLanguageCode(languageCode));
        await _tts.setPitch(1.0);
        await _tts.setSpeechRate(speechRate);
        await _tts.speak(text);
      }
    } catch (e) {
      print('TTS Error: $e');
    }
  }

  static Future<void> stop() async {
    await _tts.stop();
  }

  static String _getLanguageCode(String code) {
    // Map your language codes to TTS supported codes
    const supportedCodes = ['hi-IN', 'ta-IN', 'te-IN', 'bn-IN', 'mr-IN', 'en-US'];
    if (supportedCodes.contains('$code-IN')) return '$code-IN';
    return 'en-US'; // Default to English if not supported
  }
}