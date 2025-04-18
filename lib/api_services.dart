import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ApiServices {
  static const String dialogflowBaseUrl = 'https://dialogflow.googleapis.com/v3beta1/';
  static const String translateBaseUrl = 'https://translation.googleapis.com/language/translate/v2';

  // Replace with your actual API keys and project details
  static const String dialogflowApiKey = 'YOUR_DIALOGFLOW_API_KEY';
  static const String translateApiKey = 'YOUR_TRANSLATE_API_KEY';
  static const String dialogflowProjectId = 'YOUR_PROJECT_ID';
  static const String dialogflowAgentId = 'YOUR_AGENT_ID';
  static const String dialogflowLocation = 'YOUR_LOCATION'; // Usually 'global'

  // Dialogflow CX integration
  static Future<String> sendQueryToDialogflow(String query, String languageCode) async {
    final sessionId = 'user-session-${DateTime.now().millisecondsSinceEpoch}';
    final url = '$dialogflowBaseUrl/projects/$dialogflowProjectId/locations/$dialogflowLocation/agents/$dialogflowAgentId/sessions/$sessionId:detectIntent';

    final headers = {
      'Authorization': 'Bearer $dialogflowApiKey',
      'Content-Type': 'application/json',
    };

    final body = {
      "queryInput": {
        "text": {
          "text": query,
          "languageCode": languageCode,
        }
      },
      "queryParams": {
        "timeZone": "Asia/Kolkata"
      }
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Extract the first text response from Dialogflow
        if (responseData['queryResult']['responseMessages'] != null &&
            responseData['queryResult']['responseMessages'].isNotEmpty &&
            responseData['queryResult']['responseMessages'][0]['text'] != null &&
            responseData['queryResult']['responseMessages'][0]['text']['text'].isNotEmpty) {
          return responseData['queryResult']['responseMessages'][0]['text']['text'][0];
        }
        return 'I received your query but have no response configured.';
      } else {
        return 'Error: ${response.statusCode} - ${response.body}';
      }
    } catch (e) {
      return 'Error communicating with the server: $e';
    }
  }

  // Google Translate API integration
  static Future<String> translateText(String text, String targetLanguage) async {
    if (text.isEmpty) return text;

    final url = '$translateBaseUrl?key=$translateApiKey';

    final headers = {
      'Content-Type': 'application/json',
    };

    final body = {
      'q': text,
      'target': targetLanguage,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['translations'][0]['translatedText'];
      } else {
        return text; // Return original text if translation fails
      }
    } catch (e) {
      return text; // Return original text if translation fails
    }
  }
}

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
    // Map our language codes to TTS supported codes
    const supportedCodes = ['hi-IN', 'ta-IN', 'te-IN', 'bn-IN', 'mr-IN', 'en-US'];
    if (supportedCodes.contains('$code-IN')) return '$code-IN';
    return 'en-US'; // Default to English if not supported
  }
}