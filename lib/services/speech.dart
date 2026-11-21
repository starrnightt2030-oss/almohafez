import 'dart:async';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// الاستماع لتلاوة المستخدم بمحرّك التعرف على الكلام في الجهاز (مجاني).
class Ear {
  static final stt.SpeechToText _s = stt.SpeechToText();
  static bool _ready = false;
  static String _locale = 'ar-SA';
  static void Function()? _finish;
  static String _text = '';

  static Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _s.initialize(
        onError: (e) => _done(),
        onStatus: (st) {
          if (st == 'done') _done();
        },
      );
    } catch (_) {
      _ready = false;
    }
    if (_ready) {
      try {
        final ls = await _s.locales();
        final arabic = ls.where((l) => l.localeId.toLowerCase().startsWith('ar')).toList();
        String? pick;
        for (final pref in ['ar_sa', 'ar-sa', 'ar_eg', 'ar-eg']) {
          for (final l in arabic) {
            if (pick == null && l.localeId.toLowerCase() == pref) pick = l.localeId;
          }
        }
        _locale = pick ?? (arabic.isNotEmpty ? arabic.first.localeId : 'ar-SA');
      } catch (_) {}
    }
    return _ready;
  }

  static void _done() {
    final f = _finish;
    _finish = null;
    if (f != null) Timer(Duration(milliseconds: 250), f);
  }

  static bool get isListening => _s.isListening;

  /// يستمع حتى يسكت المستخدم، ثم يستدعي [onDone] بالنص كاملًا.
  static Future<void> listen({
    required void Function(String text) onText,
    required void Function(String text) onDone,
  }) async {
    _text = '';
    var called = false;
    _finish = () {
      if (called) return;
      called = true;
      onDone(_text);
    };
    await _s.listen(
      onResult: (SpeechRecognitionResult r) {
        _text = r.recognizedWords;
        onText(_text);
        if (r.finalResult) _done();
      },
      localeId: _locale,
      listenFor: Duration(seconds: 120),
      pauseFor: Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  static Future<void> stop() async {
    if (_s.isListening) await _s.stop();
  }

  static Future<void> cancel() async {
    _finish = null;
    if (_s.isListening) await _s.cancel();
  }
}
