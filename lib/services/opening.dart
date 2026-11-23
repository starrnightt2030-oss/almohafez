import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../data/progress.dart';
import 'voice.dart';

/// صوت الافتتاح: ﴿وَرَتِّلِ ٱلْقُرْآنَ تَرْتِيلًا﴾ بصوت الحصري (من داخل التطبيق، فيشتغل فورًا ومن غير نت)،
/// وبعدها ترحيب قصير من المعلّم حسب الوقت. بيشتغل مع كل فتح للتطبيق (مش لما يرجع من الخلفية).
class Opening {
  static const asset = 'assets/audio/voice/opening_ayah.mp3';
  static AudioPlayer? _p;
  static bool _stopped = false;

  /// الآية بس (بترجع لما تخلص).
  static Future<void> ayah() async {
    _stopped = false;
    try {
      _p ??= AudioPlayer();
      await _p!.setAsset(asset);
      final done = _p!.processingStateStream.skip(1).firstWhere((s) => s == ProcessingState.completed || s == ProcessingState.idle);
      unawaited(_p!.play());
      await done.timeout(Duration(seconds: 12), onTimeout: () => ProcessingState.completed);
    } catch (_) {}
  }

  /// الآية ثم الترحيب — للمستخدم اللي شاف المقدمة قبل كده.
  static Future<void> run() async {
    if (Progress.openingOn) await ayah();
    if (_stopped || !Progress.greetOn) return;
    await Future.delayed(Duration(milliseconds: 350));
    if (_stopped) return;
    final h = DateTime.now().hour;
    final key = Progress.wasAway ? 'greet_back' : (h >= 4 && h < 12 ? 'greet_morning' : 'greet_evening');
    await Voice.cue(key, force: true);
  }

  static Future<void> stop() async {
    _stopped = true;
    try {
      await _p?.stop();
    } catch (_) {}
  }
}
