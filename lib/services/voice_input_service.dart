import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceInputException implements Exception {
  VoiceInputException(this.message);
  final String message;

  @override
  String toString() => message;
}

class VoiceInputService {
  final _speechToText = stt.SpeechToText();
  String _currentLocale = 'en_US';
  bool _isListening = false;
  String _transcribedText = '';

  bool get isListening => _isListening;
  String get transcribedText => _transcribedText;
  bool get isAvailable => _speechToText.isAvailable;

  /// Initialize the speech-to-text engine
  Future<void> initialize({String locale = 'en_US'}) async {
    try {
      _currentLocale = locale;
      if (!_speechToText.isAvailable) {
        final available = await _speechToText.initialize(
          onError: (error) {
            debugPrint('Speech-to-text error: $error');
          },
          onStatus: (status) {
            debugPrint('Speech-to-text status: $status');
          },
        );
        if (!available) {
          throw VoiceInputException(
            'Speech-to-text is not available on this device.',
          );
        }
      }
    } catch (e) {
      throw VoiceInputException('Failed to initialize speech-to-text: $e');
    }
  }

  /// Start listening to voice input
  Future<void> startListening() async {
    if (_isListening) return;
    if (!_speechToText.isAvailable) {
      await initialize();
    }

    try {
      _transcribedText = '';
      _isListening = true;

      await _speechToText.listen(
        onResult: (result) {
          _transcribedText = result.recognizedWords;
        },
        listenOptions: stt.SpeechListenOptions(
          localeId: _currentLocale,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
        ),
        onSoundLevelChange: (level) {
          // Can be used for audio level visualization
        },
      );
    } catch (e) {
      _isListening = false;
      throw VoiceInputException('Failed to start listening: $e');
    }
  }

  /// Stop listening and return the transcribed text
  Future<String> stopListening() async {
    try {
      await _speechToText.stop();
      _isListening = false;
      return _transcribedText.trim();
    } catch (e) {
      _isListening = false;
      throw VoiceInputException('Failed to stop listening: $e');
    }
  }

  /// Cancel listening without returning results
  Future<void> cancelListening() async {
    try {
      await _speechToText.cancel();
      _isListening = false;
      _transcribedText = '';
    } catch (e) {
      throw VoiceInputException('Failed to cancel listening: $e');
    }
  }

  /// Set the language/locale for speech recognition
  Future<void> setLocale(String locale) async {
    _currentLocale = locale;
  }

  /// Get available locales
  Future<List<String>> getAvailableLocales() async {
    try {
      final locales = await _speechToText.locales();
      return locales.map((locale) => locale.localeId).toList();
    } catch (e) {
      throw VoiceInputException('Failed to get available locales: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _speechToText.cancel();
    _isListening = false;
  }
}
