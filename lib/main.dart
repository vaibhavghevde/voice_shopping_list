import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
// Note: Porcupine flutter is a placeholder here as we don't have the key or model.
// import 'package:porcupine_flutter/porcupine.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const ShoppingListApp());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  // We mock the full configuration for the prototype.
  // In production, you would configure Android foreground service settings here.
}

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Shopping List',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const ShoppingListScreen(),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<String> _items = [];
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _loadItems();
    _initSpeech();
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('shopping_list');
    if (itemsJson != null) {
      setState(() {
        _items = List<String>.from(json.decode(itemsJson));
      });
    }
  }

  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shopping_list', json.encode(_items));
  }

  void _initSpeech() async {
    await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    // In the real app, this would be triggered by Porcupine wake word in background.
    // For this prototype, we simulate the wake word activating the microphone.
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
      if (_lastWords.isNotEmpty) {
        _items.add(_lastWords);
        _lastWords = '';
        _saveItems();
      }
    });
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _saveItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Shopping List'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
            tooltip: 'Simulate Wake Word ("Add to list")',
          )
        ],
      ),
      body: Column(
        children: [
          if (_isListening)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Listening: $_lastWords',
                style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_items[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteItem(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        child: Icon(_isListening ? Icons.stop : Icons.mic),
      ),
    );
  }
}