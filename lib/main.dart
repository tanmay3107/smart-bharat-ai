import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_services.dart';
import 'settings_page.dart';
import 'text_to_speech_service.dart'; // Import the TTS service
import 'package:flutter/services.dart'; // Import for SystemNavigator
import 'history_page.dart'; // Import for HistoryPage
import 'text_to_speech_service.dart' as tts_service;
import 'dart:io';
import 'home_screen.dart';
import 'ai_assistant_page.dart';
import 'search_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Bharat AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(), // <-- Entry point
      routes: {
        '/settings': (context) => SettingsPage(),
        '/history': (context) => HistoryPage(),
        '/search': (context) => SearchPage(),
        '/assistant': (context) => const AIAssistantPage(),
      },
    );
  }
}


// Helper class for checking internet connectivity
class ConnectivityService {
  static Future<bool> checkInternetConnection() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn) {
      // Check if there's actually a connection to the internet
      try {
        final response = await InternetAddress.lookup('google.com');
        if (response.isNotEmpty && response[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException catch (_) {
        return false;
      }
    }
    return false;
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _initializeApp() async {
    await Future.delayed(Duration(seconds: 2));

    bool hasInternet = await ConnectivityService.checkInternetConnection();
    print("SplashScreen: hasInternet = $hasInternet");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? selectedLanguage = prefs.getString('languageCode');
    print("SplashScreen: selectedLanguage = $selectedLanguage");

    if (!mounted) return; // Add this check

    if (!hasInternet) {
      _showNoInternetDialog();
      return;
    }

    if (selectedLanguage != null) {
      if (mounted) { // Add this check before navigation
        print("SplashScreen: Navigating to /home"); // Add this line

        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      if (mounted) { // Add this check before navigation
        print("SplashScreen: Navigating to /language"); // Add this line

        Navigator.pushReplacementNamed(context, '/language');
      }
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('No Internet Connection'),
        content: Text('This app requires internet connection to function properly.'),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) { // Add this check
                Navigator.pop(context);
                _initializeApp();
              }
            },
            child: Text('Retry'),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: Text('Exit'),
          ),
        ],
      ),
    ).then((_) {});
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 20),
            Text(
              'AI Assistant for Rural India',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

// 2. Language Selection Screen
class LanguageSelectionScreen extends StatefulWidget {
  @override
  _LanguageSelectionScreenState createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguageCode;
  final List<String> _languageCodes = ['hi', 'ta', 'te', 'bn', 'mr', 'en'];
  final Map<String, String> _languageNames = {
    'hi': 'हिंदी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'bn': 'বাংলা (Bengali)',
    'mr': 'मराठी (Marathi)',
    'en': 'English',
  };

  Future<void> _saveLanguagePreference(String languageCode) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', languageCode);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Your Language'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Please select your preferred language',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 30),
              DropdownButton<String>(
                value: _selectedLanguageCode,
                hint: Text('Select Language'),
                isExpanded: true,
                items: _languageCodes.map((String code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text(_languageNames[code]!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLanguageCode = newValue;
                  });
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _selectedLanguageCode != null
                    ? () => _saveLanguagePreference(_selectedLanguageCode!)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text('Continue', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. Home Screen
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastSpokenWords = '';
  bool _isProcessing = false;
  String _currentLanguage = 'hi';
  String _greeting = 'नमस्ते! आप क्या जानना चाहते हैं?';

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguage = prefs.getString('languageCode') ?? 'hi';
      _updateGreeting();
    });
  }

  void _updateGreeting() {
    final greetings = {
      'hi': 'नमस्ते! आप क्या जानना चाहते हैं?',
      'ta': 'வணக்கம்! நீங்கள் என்ன தெரிந்து கொள்ள வேண்டும்?',
      'te': 'నమస్కారం! మీరు ఏమి తెలుసుకోవాలనుకుంటున్నారు?',
      'bn': 'নমস্কার! আপনি কি জানতে চান?',
      'mr': 'नमस्कार! तुम्हाला काय जाणून घ्यायचे आहे?',
      'en': 'Hello! What would you like to know?',
    };
    _greeting = greetings[_currentLanguage] ?? greetings['hi']!;
  }

  void _initSpeech() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech status: $status"),
      onError: (error) => print("Speech error: $error"),
    );
    if (!available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  void _startListening() async {
    if (!_isListening && !_isProcessing) {
      setState(() {
        _lastSpokenWords = '';
        _isListening = true;
      });

      await _speech.listen(
        onResult: (result) {
          setState(() {
            _lastSpokenWords = result.recognizedWords;
          });
          if (result.finalResult) {
            _stopListening();
            _processVoiceInput(_lastSpokenWords);
          }
        },
        listenFor: Duration(seconds: 10),
        localeId: _currentLanguage,
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _processVoiceInput(String query) async {
    if (query.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      String response = await ApiServices.sendQueryToDialogflow(query, _currentLanguage);

      Navigator.pushNamed(
        context,
        '/response',
        arguments: {
          'query': query,
          'response': response,
          'language': _currentLanguage,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing your request: $e')),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _navigateToResponse(String category) async {
    String query = '';
    switch (category) {
      case 'Healthcare':
        query = _currentLanguage == 'hi'
            ? 'स्वास्थ्य सेवा के बारे में जानकारी'
            : 'Information about healthcare';
        break;
      case 'Govt. Schemes':
        query = _currentLanguage == 'hi'
            ? 'सरकारी योजनाओं के बारे में जानकारी'
            : 'Information about government schemes';
        break;
      case 'Weather':
        query = _currentLanguage == 'hi'
            ? 'मौसम के बारे में जानकारी'
            : 'Information about weather';
        break;
    }

    _processVoiceInput(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _greeting,
                  style: TextStyle(fontSize: 20, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _speech.isAvailable ? _startListening : null,
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(30),
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                if (_lastSpokenWords.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            _currentLanguage == 'hi' ? 'आपने कहा:' : 'You said:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(_lastSpokenWords),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 40),
                Text(
                  _currentLanguage == 'hi'
                      ? 'या मैन्युअली एक्सप्लोर करें:'
                      : 'Or explore manually:',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildCategoryButton(
                      icon: Icons.local_hospital,
                      label: _currentLanguage == 'hi' ? 'स्वास्थ्य सेवा' : 'Healthcare',
                      category: 'Healthcare',
                    ),
                    _buildCategoryButton(
                      icon: Icons.assignment,
                      label: _currentLanguage == 'hi' ? 'सरकारी योजनाएं' : 'Govt. Schemes',
                      category: 'Govt. Schemes',
                    ),
                    _buildCategoryButton(
                      icon: Icons.cloud,
                      label: _currentLanguage == 'hi' ? 'मौसम' : 'Weather',
                      category: 'Weather',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      _currentLanguage == 'hi'
                          ? 'प्रोसेसिंग...'
                          : 'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String label,
    required String category,
  }) {
    return ElevatedButton(
      onPressed: () => _navigateToResponse(category),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}

// 4. Response Page
class ResponsePage extends StatefulWidget {
  @override
  _ResponsePageState createState() => _ResponsePageState();
}

class _ResponsePageState extends State<ResponsePage> {
  late Map<String, dynamic> _responseData;
  bool _isSpeaking = false;
  late FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _responseData = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    _setupTTS();
  }

  void _setupTTS() async {
    await _tts.setLanguage(_responseData['language'] ?? 'hi');
    _tts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('TTS Error: $msg')),
      );
    });
  }

  void _speakResponse() async {
    setState(() => _isSpeaking = true);
    await _tts.speak(_responseData['response']);
  }

  void _stopSpeaking() async {
    await _tts.stop();
    setState(() => _isSpeaking = false);
  }

  Future<void> _saveToHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('queryHistory') ?? [];

    history.add(json.encode({
      'query': _responseData['query'],
      'response': _responseData['response'],
      'language': _responseData['language'],
      'timestamp': DateTime.now().toIso8601String(),
    }));

    await prefs.setStringList('queryHistory', history);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to history')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Response'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _responseData['language'] == 'hi' ? 'आपका प्रश्न:' : 'Your Question:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_responseData['query']),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _responseData['language'] == 'hi' ? 'उत्तर:' : 'Response:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(_responseData['response']), // Make sure _responseData['response'] exists
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => tts_service.TextToSpeechService.speak(_responseData['response'], _responseData['language']),
              icon: Icon(Icons.speaker_phone),
              label: Text('Speak'),
            ),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _saveToHistory(),
              icon: Icon(Icons.save),
              label: Text('Save to History'),
            ),
          ],
        ),
      ),
    );
  }
}