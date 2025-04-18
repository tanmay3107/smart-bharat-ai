import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedLanguage;
  bool _ttsEnabled = true;
  double _speechRate = 0.5;
  bool _saveHistory = true;
  bool _isLoading = true;

  final Map<String, String> _languageOptions = {
    'hi': 'हिंदी (Hindi)',
    'ta': 'தமிழ் (Tamil)',
    'te': 'తెలుగు (Telugu)',
    'bn': 'বাংলা (Bengali)',
    'mr': 'मराठी (Marathi)',
    'en': 'English',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('languageCode') ?? 'hi';
      _ttsEnabled = prefs.getBool('ttsEnabled') ?? true;
      _speechRate = prefs.getDouble('speechRate') ?? 0.5;
      _saveHistory = prefs.getBool('saveHistory') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', _selectedLanguage!);
    await prefs.setBool('ttsEnabled', _ttsEnabled);
    await prefs.setDouble('speechRate', _speechRate);
    await prefs.setBool('saveHistory', _saveHistory);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settings saved successfully'),
        duration: Duration(seconds: 2),
      ),
    );
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Settings'),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: _selectedLanguage,
                isExpanded: true,
                hint: Text('Select Language'),
                items: _languageOptions.keys.map((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(_languageOptions[key]!),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedLanguage = newValue;
                    });
                  }
                },
              ),
              SizedBox(height: 20),
              Text(
                'Text-to-Speech (TTS)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: Text('Enable TTS'),
                value: _ttsEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    _ttsEnabled = newValue;
                  });
                },
              ),
              if (_ttsEnabled)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Speech Rate', style: TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _speechRate,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: _speechRate.toStringAsFixed(1),
                        onChanged: (double newValue) {
                          setState(() {
                            _speechRate = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              Text(
                'History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SwitchListTile(
                title: Text('Save Query History'),
                value: _saveHistory,
                onChanged: (bool newValue) {
                  setState(() {
                    _saveHistory = newValue;
                  });
                },
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveSettings,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Text('Save Settings', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ));
  }
}