import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'text_to_speech_service.dart'; // Import the TTS service

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? historyStrings = prefs.getStringList('queryHistory');
    if (historyStrings != null) {
      setState(() {
        _history = historyStrings.map((item) => json.decode(item) as Map<String, dynamic>).toList().reversed.toList();
      });
    }
  }

  Future<void> _clearHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('queryHistory');
    setState(() {
      _history.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('History cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Query History'),
        actions: [
          if (_history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: _clearHistory,
            ),
        ],
      ),
      body: _history.isEmpty
          ? Center(child: Text('No history available.'))
          : ListView.builder(
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final entry = _history[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Query: ${entry['query']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Response: ${entry['response']}'),
                  SizedBox(height: 8),
                  Text(
                    'Language: ${entry['language']}',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          TextToSpeechService.speak(entry['response'], entry['language']);
                        },
                        icon: Icon(Icons.speaker_phone),
                        label: Text('Speak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}