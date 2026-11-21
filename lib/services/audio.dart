import 'dart:async';
import 'package:just_audio/just_audio.dart';

/// تشغيل تلاوة الشيخ آيةً آية.
class Sheikh {
  static final AudioPlayer _player = AudioPlayer();
  static Completer<void>? _cancel;

  static String url(String folder, int s, int a) =>
      'https://everyayah.com/data/$folder/${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';

  /// يشغّل الآية وينتظر حتى تنتهي. [fraction] لتشغيل جزء من بداية الآية فقط.
  static Future<void> play(String folder, int s, int a, {double speed = 1.0, double? fraction}) async {
    await stop();
    final c = Completer<void>();
    _cancel = c;
    final d = await _player.setUrl(url(folder, s, a));
    if (c.isCompleted) return;
    if (fraction != null && d != null) {
      await _player.setClip(end: Duration(milliseconds: (d.inMilliseconds * fraction).round()));
    }
    await _player.setSpeed(speed);
    final done = _player.processingStateStream.firstWhere((st) => st == ProcessingState.completed);
    unawaited(_player.play());
    await Future.any([done, c.future]);
    if (identical(_cancel, c)) _cancel = null;
    await _player.pause();
  }

  static Future<void> stop() async {
    final c = _cancel;
    _cancel = null;
    if (c != null && !c.isCompleted) c.complete();
    await _player.stop();
  }
}
