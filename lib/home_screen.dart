import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';
import 'api_services.dart'; // Ensure this file exists and the path is correct
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart'; // Ensure this file exists and the path is correct
import 'history_page.dart'; // Ensure this file exists and the path is correct

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PersistentTabController _controller = PersistentTabController(initialIndex: 3); // Start on the AI tab

  List<Widget> _buildScreens() {
    return [
      Center(child: Text("Home Screen Content", style: TextStyle(color: Colors.black))), // Replace with your actual Home content
      Center(child: Text("Search Screen Content", style: TextStyle(color: Colors.black))), // Replace with your actual Search content
      Center(child: Icon(Icons.add_circle, size: 50, color: Colors.black)), // Replace with your actual Add content
      // Your previous AI Assistant Tab (the content of _buildAiAssistantTab() from your previous HomeScreen)
      _buildAiAssistantTab(),
      SettingsPage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home),
        title: ("Home"),
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.search),
        title: ("Search"),
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.add_circle_outline),
        title: ("Add"),
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.mic),
        title: ("AI"),
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.settings),
        title: ("Settings"),
        activeColorPrimary: Colors.blueAccent,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  Widget _buildAiAssistantTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _greeting, // Ensure _greeting is defined in this class or accessed appropriately
                style: TextStyle(fontSize: 20, height: 1.5),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _speech.isAvailable ? _startListening : null, // Ensure _speech and _startListening are defined or accessed
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(30),
                  backgroundColor: _isListening ? Colors.red : Colors.green, // Ensure _isListening is defined or accessed
                ),
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic, // Ensure _isListening is defined or accessed
                  size: 50,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              if (_lastSpokenWords.isNotEmpty) // Ensure _lastSpokenWords is defined or accessed
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          _currentLanguage == 'hi' ? 'आपने कहा:' : 'You said:', // Ensure _currentLanguage is defined or accessed
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(_lastSpokenWords), // Ensure _lastSpokenWords is defined or accessed
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 40),
              Text(
                _currentLanguage == 'hi'
                    ? 'या मैन्युअली एक्सप्लोर करें:'
                    : 'Or explore manually:', // Ensure _currentLanguage is defined or accessed
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCategoryButton( // Ensure _buildCategoryButton is defined or accessed
                    icon: Icons.local_hospital,
                    label: _currentLanguage == 'hi' ? 'स्वास्थ्य सेवा' : 'Healthcare', // Ensure _currentLanguage is defined or accessed
                    category: 'Healthcare',
                  ),
                  _buildCategoryButton( // Ensure _buildCategoryButton is defined or accessed
                    icon: Icons.assignment,
                    label: _currentLanguage == 'hi' ? 'सरकारी योजनाएं' : 'Govt. Schemes', // Ensure _currentLanguage is defined or accessed
                    category: 'Govt. Schemes',
                  ),
                  _buildCategoryButton( // Ensure _buildCategoryButton is defined or accessed
                    icon: Icons.cloud,
                    label: _currentLanguage == 'hi' ? 'मौसम' : 'Weather', // Ensure _currentLanguage is defined or accessed
                    category: 'Weather',
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isProcessing) // Ensure _isProcessing is defined or accessed
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
                        : 'Processing...', // Ensure _currentLanguage is defined or accessed
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String label,
    required String category,
  }) {
    return ElevatedButton(
      onPressed: () => _navigateToResponse(category), // Ensure _navigateToResponse is defined or accessed
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

    _processVoiceInput(query); // Ensure _processVoiceInput is defined or accessed
  }

  void _processVoiceInput(String query) async {
    if (query.isEmpty) return;

    setState(() => _isProcessing = true); // Ensure _isProcessing is defined or accessed

    try {
      String response = await ApiServices.sendQueryToDialogflow(query, _currentLanguage); // Ensure ApiServices is imported

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
      setState(() => _isProcessing = false); // Ensure _isProcessing is defined or accessed
    }
  }

  final stt.SpeechToText _speech = stt.SpeechToText(); // Define _speech
  bool _isListening = false; // Define _isListening
  String _lastSpokenWords = ''; // Define _lastSpokenWords
  bool _isProcessing = false; // Define _isProcessing
  String _currentLanguage = 'hi'; // Define _currentLanguage
  String _greeting = 'नमस्ते! आप क्या जानना चाहते हैं?'; // Define _greeting

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

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineInSafeArea: true,
      backgroundColor: Colors.white, // Default is Colors.white.
      handleAndroidBackButtonPress: true, // Default is true.
      resizeToAvoidBottomInset: true, // This needs to be true if you want to move up the screen when keyboard appears. Default is true.
      stateManagement: true, // Default is true.
      hideNavigationBarWhenKeyboardShows: true, // Recommended to set 'resizeToAvoidBottomInset' as true while using this argument. Default is true.
      decoration: const NavBarDecoration( // Added const here
        borderRadius: BorderRadius.circular(10.0),
        colorBehindNavBar: Colors.white,
      ),
      popAllScreensOnTapOfSelectedTab: true,
      popActionScreens: PopActionScreensType.all,
      itemAnimationProperties: const ItemAnimationProperties( // Added const here
        duration: Duration(milliseconds: 200),
        curve: Curves.ease,
      ),
      screenTransitionAnimation: const ScreenTransitionAnimation( // Added const here
        animateTabTransition: true,
        curve: Curves.ease,
        duration: Duration(milliseconds: 200),
      ),
      navBarStyle: NavBarStyle.style1, // Choose the nav bar style with this property.
    );
  }
}