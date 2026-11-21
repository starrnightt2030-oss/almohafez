import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../data/voice_lines.dart';
import '../data/progress.dart';

/// الصوت الموجّه داخل التطبيق: يقرأ الشروحات والتوجيهات.
/// إذا وُجد ملف مسجّل بصوتك في assets/audio يُشغَّل بدل القراءة الآلية.
class Voice {
  static final FlutterTts _tts = FlutterTts();
  static final AudioPlayer _player = AudioPlayer();
  static bool _ready = false;
  static Set<String> _assets = {};
  static int _token = 0;

  static Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      _assets = m.listAssets().where((a) => a.startsWith('assets/audio/')).toSet();
    } catch (_) {}
    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(Progress.voiceRate);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
    } catch (_) {}
  }

  static bool get enabled => Progress.voiceOn;

  static String? _asset(String path) {
    for (final ext in ['mp3', 'm4a', 'wav', 'ogg']) {
      final p = '$path.$ext';
      if (_assets.contains(p)) return p;
    }
    return null;
  }

  /// هل يوجد تسجيل صوتي بشري لهذه الفقرة؟
  static bool hasRecording(String lessonId, int para) => _asset('assets/audio/lessons/${lessonId}_${para + 1}') != null;

  /// يقرأ نصًا (أو يشغّل التسجيل المقابل) وينتظر حتى ينتهي.
  static Future<void> say(String text, {String? clip, bool force = false}) async {
    if (!enabled && !force) return;
    await init();
    await stop();
    final t = ++_token;
    final a = clip == null ? null : _asset(clip);
    if (a != null) {
      try {
        await _player.setAsset(a);
        final done = _player.processingStateStream.skip(1).firstWhere((s) => s == ProcessingState.completed || s == ProcessingState.idle);
        unawaited(_player.play());
        await done;
        return;
      } catch (_) {}
    }
    if (t != _token) return;
    try {
      await _tts.setSpeechRate(Progress.voiceRate);
      await _tts.speak(text);
    } catch (_) {}
  }

  /// قراءة فقرة درس: التسجيل البشري إن وُجد وإلا القراءة الآلية.
  static Future<void> narrate(String lessonId, int para, String text) =>
      say(text, clip: 'assets/audio/lessons/${lessonId}_${para + 1}', force: true);

  static Future<void> stop() async {
    _token++;
    try {
      await _tts.stop();
    } catch (_) {}
    try {
      await _player.stop();
    } catch (_) {}
  }

  static final _rnd = math.Random();

  /// هل يوجد تسجيل لهذا المسار (بدون الامتداد)؟
  static bool has(String path) => _asset(path) != null;

  /// عبارة تفاعلية جاهزة: يختار صيغة عشوائية، ويشغّل تسجيلها إن وُجد وإلا يقرؤها آليًا.
  static Future<void> cue(String key, {bool force = false}) {
    final lines = voiceLines[key];
    if (lines == null || lines.isEmpty) return Future.value();
    final i = _rnd.nextInt(lines.length);
    return say(lines[i], clip: 'assets/audio/voice/${key}_${i + 1}', force: force);
  }

  /// هل سُجّلت عبارات هذا الحدث؟
  static bool hasCue(String key) => has('assets/audio/voice/${key}_1');

  static Future<void> wellDone() => cue('recite_correct');
  static Future<void> yourTurn() => cue('your_turn');
  static Future<void> correct() => cue('quiz_correct');
  static Future<void> wrong(String right) => cue('quiz_wrong');
}
