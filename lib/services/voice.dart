import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math' as math;
import 'package:just_audio/just_audio.dart';
import '../data/voice_lines.dart';
import '../data/progress.dart';
import 'voice_pack.dart';

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
    await VoicePack.load();
    try {
      await _tts.setLanguage('ar-SA').timeout(Duration(seconds: 5));
      await _tts.setSpeechRate(Progress.voiceRate).timeout(Duration(seconds: 3));
      await _tts.setPitch(1.0).timeout(Duration(seconds: 3));
      await _tts.awaitSpeakCompletion(true).timeout(Duration(seconds: 3));
    } catch (_) {}
    await applyVoice();
  }

  /// أصوات العربي المتاحة في محرّك الكلام على الموبايل
  static Future<List<Map<String, String>>> arabicVoices() async {
    try {
      final v = await _tts.getVoices.timeout(Duration(seconds: 5));
      return (v as List)
          .map((e) => (e as Map).map((k, x) => MapEntry('$k', '$x')))
          .where((m) => (m['locale'] ?? '').toLowerCase().startsWith('ar'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// ترتيب الأصوات: المصري والرجالي الأول (لحد ما المقاطع تتسجّل بصوت حقيقي)
  static int _rank(Map<String, String> m) {
    final n = (m['name'] ?? '').toLowerCase(), l = (m['locale'] ?? '').toLowerCase().replaceAll('_', '-');
    var r = 0;
    if (n.contains('female') || n.contains('#female')) {
      r -= 6;
    } else if (n.contains('male')) {
      r += 6;
    }
    if (l == 'ar-eg' || n.contains('ar-eg') || n.contains('egypt')) r += 4;
    if (n.contains('shakir') || n.contains('ard') || n.contains('arc')) r += 2;
    if (n.contains('local')) r += 1;
    if (m['network_required'] == '1' || m['network_required'] == 'true') r -= 1;
    return r;
  }

  /// اسم الصوت المستخدم دلوقتي
  static String? current;

  static Future<void> applyVoice([String? name]) async {
    final list = await arabicVoices();
    if (list.isEmpty) return;
    Map<String, String>? pick;
    final want = name ?? Progress.ttsVoice;
    if (want != null) pick = list.where((m) => m['name'] == want).firstOrNull;
    if (pick == null) {
      list.sort((a, b) => _rank(b) - _rank(a));
      pick = list.first;
    }
    try {
      await _tts.setVoice({'name': pick['name']!, 'locale': pick['locale']!}).timeout(Duration(seconds: 3));
      current = pick['name'];
    } catch (_) {}
  }

  static bool get enabled => Progress.voiceOn;

  /// يجهّز تسجيل الفقرة الجاية وإحنا بنسمع الحالية
  static void prefetch(String clip) {
    if (_asset(clip) == null) unawaited(VoicePack.fetch('$clip.mp3'));
  }

  /// مسار التسجيل: من التطبيق نفسه، أو من حزمة الصوت المتحمّلة (بيبدأ بـ file:).
  static String? _asset(String path) {
    for (final ext in ['mp3', 'm4a', 'wav', 'ogg']) {
      final p = '$path.$ext';
      if (_assets.contains(p)) return p;
      final f = VoicePack.file(p);
      if (f != null) return 'file:$f';
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
    var a = clip == null ? null : _asset(clip);
    // مش متحمّل لسه؟ نجيبه حالًا من الحزمة (شرح الدروس والأحاديث)
    if (a == null && clip != null && (clip.contains('/lessons/') || clip.contains('/hadith/') || clip.contains('/quiz/'))) {
      final f = await VoicePack.fetch('$clip.mp3');
      if (t != _token) return;
      if (f != null) a = 'file:$f';
    }
    if (a != null) {
      try {
        Duration? len;
        if (a.startsWith('file:')) {
          len = await _player.setFilePath(a.substring(5));
        } else {
          len = await _player.setAsset(a);
        }
        await _player.setVolume(1.0);
        final done = _player.processingStateStream.skip(1).firstWhere((s) => s == ProcessingState.completed || s == ProcessingState.idle);
        unawaited(_player.play());
        // مهلة أمان: الصوت الموجّه عمره ما يوقّف الجلسة (ولا يمنع الشيخ إنه يبدأ)
        await done.timeout((len ?? Duration(seconds: 20)) + Duration(seconds: 4), onTimeout: () => ProcessingState.completed);
        return;
      } catch (_) {}
    }
    if (t != _token) return;
    try {
      await _tts.setSpeechRate(Progress.voiceRate).timeout(Duration(seconds: 3));
      await _tts.speak(text).timeout(Duration(seconds: 25));
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
