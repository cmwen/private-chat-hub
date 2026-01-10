import 'package:flutter_tts/flutter_tts.dart';

/// Service for managing text-to-speech functionality.
/// 
/// Provides methods to speak text using Android's native TTS engine,
/// with support for both complete messages and streaming mode.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentMessageId;
  
  /// Initialize the TTS engine with default settings.
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set language to English (US)
      await _flutterTts.setLanguage('en-US');
      
      // Set speech rate (0.0 to 1.0, where 0.5 is normal)
      await _flutterTts.setSpeechRate(0.5);
      
      // Set volume (0.0 to 1.0)
      await _flutterTts.setVolume(1.0);
      
      // Set pitch (0.5 to 2.0, where 1.0 is normal)
      await _flutterTts.setPitch(1.0);
      
      // Set up completion handler
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentMessageId = null;
      });
      
      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _currentMessageId = null;
      });
      
      _isInitialized = true;
    } catch (e) {
      // Failed to initialize TTS
      _isInitialized = false;
    }
  }
  
  /// Speak the given text.
  /// 
  /// [text] - The text to speak
  /// [messageId] - Optional message ID to track which message is being spoken
  /// 
  /// Returns true if speech started successfully, false otherwise.
  Future<bool> speak(String text, {String? messageId}) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) return false;
    }
    
    // Stop any ongoing speech
    if (_isSpeaking) {
      await stop();
    }
    
    try {
      _currentMessageId = messageId;
      _isSpeaking = true;
      
      // Remove markdown formatting for better speech
      final cleanText = _cleanMarkdown(text);
      
      await _flutterTts.speak(cleanText);
      return true;
    } catch (e) {
      _isSpeaking = false;
      _currentMessageId = null;
      return false;
    }
  }
  
  /// Stop the current speech.
  Future<void> stop() async {
    if (!_isInitialized) return;
    
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _currentMessageId = null;
    } catch (e) {
      // Ignore errors when stopping
    }
  }
  
  /// Pause the current speech.
  Future<void> pause() async {
    if (!_isInitialized || !_isSpeaking) return;
    
    try {
      await _flutterTts.pause();
    } catch (e) {
      // Ignore errors when pausing
    }
  }
  
  /// Check if TTS is currently speaking.
  bool get isSpeaking => _isSpeaking;
  
  /// Get the message ID of the currently speaking message.
  String? get currentMessageId => _currentMessageId;
  
  /// Check if a specific message is being spoken.
  bool isSpeakingMessage(String messageId) {
    return _isSpeaking && _currentMessageId == messageId;
  }
  
  /// Clean markdown formatting from text for better speech output.
  String _cleanMarkdown(String text) {
    var cleaned = text;
    
    // Remove code blocks
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '[code block]');
    
    // Remove inline code
    cleaned = cleaned.replaceAll(RegExp(r'`[^`]+`'), '[code]');
    
    // Remove bold/italic markers
    cleaned = cleaned.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'__([^_]+)__'), r'$1');
    cleaned = cleaned.replaceAll(RegExp(r'_([^_]+)_'), r'$1');
    
    // Remove headers
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s+'), '');
    
    // Remove links but keep text
    cleaned = cleaned.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    
    // Remove list markers
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[-*+]\s+', multiLine: true), '');
    cleaned = cleaned.replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '');
    
    // Remove excess whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.trim();
    
    return cleaned;
  }
  
  /// Dispose of resources.
  void dispose() {
    stop();
  }
}
