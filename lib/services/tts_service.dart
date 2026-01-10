import 'package:flutter_tts/flutter_tts.dart';

/// Callback function type for TTS state changes
typedef OnTtsStateChanged = void Function();

/// Service for managing text-to-speech functionality.
///
/// Provides methods to speak text using Android's native TTS engine,
/// with support for both complete messages and streaming mode.
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  String? _currentMessageId;
  OnTtsStateChanged? _onStateChanged;

  /// Set callback to be notified when TTS state changes
  void setOnStateChanged(OnTtsStateChanged? callback) {
    _onStateChanged = callback;
  }

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
        _onStateChanged?.call();
      });

      // Set up error handler
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        _currentMessageId = null;
        _onStateChanged?.call();
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
  /// [speed] - Speech rate (0.0 to 1.0, where 0.5 is normal speed)
  ///
  /// Returns true if speech started successfully, false otherwise.
  Future<bool> speak(String text, {String? messageId, double? speed}) async {
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
      _onStateChanged?.call();

      // Set speech rate if provided
      if (speed != null) {
        await _flutterTts.setSpeechRate(speed);
      }

      // Remove markdown formatting for better speech
      final cleanText = _cleanMarkdown(text);

      await _flutterTts.speak(cleanText);
      return true;
    } catch (e) {
      _isSpeaking = false;
      _currentMessageId = null;
      _onStateChanged?.call();
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
      _onStateChanged?.call();
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
  ///
  /// Uses callback-based regex replacements (replaceAllMapped) instead of
  /// string replacements to avoid literal $1, $2 etc. appearing in output.
  /// This prevents TTS from reading "ONE DOLLAR" when regex captures are used.
  String _cleanMarkdown(String text) {
    if (text.isEmpty) return text;

    var cleaned = text;

    // 1. Remove code blocks first (to avoid processing their contents)
    cleaned = cleaned.replaceAll(RegExp(r'```[\s\S]*?```'), '');
    cleaned = cleaned.replaceAll(RegExp(r'~~~[\s\S]*?~~~'), '');

    // 2. Remove inline code
    cleaned = cleaned.replaceAll(RegExp(r'`[^`]+`'), '');

    // 3. Remove headers - use callback to avoid $1 literal
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^#+\s+(.*)$', multiLine: true),
      (match) => match.group(1) ?? '',
    );

    // 4. Remove bold/italic markers - use callbacks instead of r'$1'
    // Bold: **text** or __text__
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*\*([^*]+)\*\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'__([^_]+)__'),
      (match) => match.group(1) ?? '',
    );

    // Italic: *text* or _text_
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\*([^*]+)\*'),
      (match) => match.group(1) ?? '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'_([^_]+)_'),
      (match) => match.group(1) ?? '',
    );

    // 5. Remove links but keep text
    // Standard links: [text](url)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\([^)]+\)'),
      (match) => match.group(1) ?? '',
    );
    // Reference links: [text][ref]
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\[[^\]]*\]'),
      (match) => match.group(1) ?? '',
    );

    // 6. Remove images
    cleaned = cleaned.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');

    // 7. Remove blockquotes
    cleaned = cleaned.replaceAll(RegExp(r'^>\s+', multiLine: true), '');

    // 8. Remove list markers - use callbacks
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s*[-*+]\s+', multiLine: true),
      (match) => '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s*\d+\.\s+', multiLine: true),
      (match) => '',
    );

    // 9. Remove strikethrough ~~text~~
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'~~([^~]+)~~'),
      (match) => match.group(1) ?? '',
    );

    // 10. Clean up punctuation that was marked for emphasis
    // Repeated punctuation: !! → !, ?? → ?, ... → ...
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'([!?.])\1+'),
      (match) => match.group(1) ?? '.',
    );

    // 11. Remove HTML tags
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]+>'), '');

    // 12. Remove stray brackets and parentheses (after markdown processing)
    cleaned = cleaned.replaceAll(RegExp(r'[\[\]]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\(+\)'), '');

    // 13. Handle dollar signs and currency (AFTER all markdown processing)
    // This prevents issues with $1 from regex replacements
    // Replace currency patterns: $100 → 100 dollars
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\$(\d+(?:\.\d{2})?)'),
      (match) => '${match.group(1)} dollars',
    );

    // Replace remaining dollar signs in variable names ($var → var)
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\$([a-zA-Z_])'),
      (match) => match.group(1) ?? '',
    );

    // 14. Handle LaTeX and math expressions
    // Remove display math: $$...$$
    cleaned = cleaned.replaceAll(RegExp(r'\$\$[\s\S]*?\$\$'), '');
    // Remove inline LaTeX: \(... \) and \[... \]
    cleaned = cleaned.replaceAll(RegExp(r'\\\([\s\S]*?\\\)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\\\[[\s\S]*?\\\]'), '');

    // 15. Normalize whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    cleaned = cleaned.replaceAll(RegExp(r' {2,}'), ' ');
    cleaned = cleaned.trim();

    return cleaned;
  }

  /// Dispose of resources.
  void dispose() {
    stop();
  }
}
