import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/message.dart';
import '../services/gemini_service.dart';

/// Provider class to manage chat state and functionality
class ChatProvider with ChangeNotifier {
  // State variables
  final List<Message> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _listeningText = '';

  // Services
  final GeminiService _geminiService = GeminiService();
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _speechInitialized = false;
  bool _isSpeaking = false;

  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  String get listeningText => _listeningText;
  bool get isSpeaking => _isSpeaking;

  ChatProvider() {
    _initializeTts();
    _initializeSpeech();
  }

  /// Initialize Text-to-Speech
  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  /// Initialize Speech-to-Text
  Future<void> _initializeSpeech() async {
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech error: $error'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );
    } catch (e) {
      debugPrint('Speech initialization error: $e');
    }
  }

  /// Send a text message to Gemini
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = Message.user(text.trim());
    _messages.add(userMessage);
    notifyListeners();

    // Show typing indicator
    _isTyping = true;
    notifyListeners();

    try {
      // Check if API key is configured
      if (!_geminiService.isApiKeyConfigured()) {
        throw Exception(
          'API key not configured. Please add your Gemini API key.',
        );
      }

      // Get response from Gemini
      final response = await _geminiService.sendMessage(text.trim());

      // Add AI response
      final aiMessage = Message.ai(response);
      _messages.add(aiMessage);
    } catch (e) {
      // Add error message
      final errorMessage = Message.ai(
        'Sorry, I encountered an error: ${e.toString()}',
        isError: true,
      );
      _messages.add(errorMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  /// Start listening for voice input
  Future<void> startListening() async {
    if (!_speechInitialized) {
      await _initializeSpeech();
    }

    if (_speechInitialized && !_isListening) {
      _isListening = true;
      _listeningText = '';
      notifyListeners();

      await _speechToText.listen(
        onResult: (result) {
          _listeningText = result.recognizedWords;
          notifyListeners();

          // If the user stops speaking, send the message
          if (result.finalResult) {
            stopListening();
            if (_listeningText.isNotEmpty) {
              sendMessage(_listeningText);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        // ignore: deprecated_member_use
        partialResults: true,
        // ignore: deprecated_member_use
        cancelOnError: true,
      );
    }
  }

  /// Stop listening for voice input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  /// Speak the given text using TTS
  Future<void> speak(String text) async {
    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
        _isSpeaking = false;
      } else {
        _isSpeaking = true;
        notifyListeners();
        await _flutterTts.speak(text);
      }
    } catch (e) {
      debugPrint('TTS error: $e');
      _isSpeaking = false;
      notifyListeners();
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  /// Clear all messages
  void clearChat() {
    _messages.clear();
    _isTyping = false;
    _isListening = false;
    _listeningText = '';
    stopSpeaking();
    notifyListeners();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speechToText.stop();
    super.dispose();
  }
}
