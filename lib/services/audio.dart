import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'opening.dart';

/// تشغيل تلاوة الشيخ آيةً آية.
///
/// عشان الشيخ مايسكتش أبدًا من غير سبب، كل آية بتتجرّب بأكتر من طريقة لحد ما واحدة تشتغل فعلًا:
/// ١) نسخة محفوظة على الموبايل (لو الآية اتسمعت قبل كده)
/// ٢) تشغيل مباشر من EveryAyah  ٣) من سيرفر احتياطي لنفس التلاوات
/// ٤) تحميل الملف على الموبايل وتشغيله منه
/// وكل طريقة ليها مهلة، ولو الصوت ما بدأش فعلًا خلال ثواني بنجرّب اللي بعدها.
class Sheikh {
  static final AudioPlayer _player = AudioPlayer();
  static Completer<void>? _cancel;

  /// آخر مشكلة حصلت (للتشخيص)
  static String lastError = '';

  static const _hosts = [
    'https://everyayah.com/data',
    'https://mirrors.quranicaudio.com/everyayah',
  ];

  static String _file(int s, int a) => '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';
  static String url(String folder, int s, int a, [int host = 0]) => '${_hosts[host]}/$folder/${_file(s, a)}';

  static Directory? _dir;
  static Future<File> _cacheFile(String folder, int s, int a) async {
    _dir ??= Directory('${(await getApplicationSupportDirectory()).path}/ayat');
    return File('${_dir!.path}/$folder/${_file(s, a)}');
  }

  /// تحميل الآية على الموبايل (من أي سيرفر يرد)، وبتتحفظ عشان المرة الجاية تشتغل فورًا ومن غير نت
  static Future<File> _download(String folder, int s, int a) async {
    final f = await _cacheFile(folder, s, a);
    Object? err;
    for (var h = 0; h < _hosts.length; h++) {
      try {
        final r = await http.get(Uri.parse(url(folder, s, a, h))).timeout(Duration(seconds: 25));
        if (r.statusCode == 200 && r.bodyBytes.length > 2000) {
          await f.parent.create(recursive: true);
          final tmp = File('${f.path}.part');
          await tmp.writeAsBytes(r.bodyBytes, flush: true);
          await tmp.rename(f.path);
          return f;
        }
        err = 'HTTP ${r.statusCode}';
      } catch (e) {
        err = e;
      }
    }
    throw Exception('download failed: $err');
  }

  /// بيحفظ الآية في الخلفية بعد ما تشتغل أونلاين، عشان التكرار والمراجعة يبقوا فوريين
  static void _keep(String folder, int s, int a) {
    _cacheFile(folder, s, a).then((f) async {
      if (!await f.exists()) await _download(folder, s, a);
    }).catchError((_) {});
  }

  /// عدد آيات السورة المحفوظة على الموبايل لهذا القارئ
  static Future<int> cachedCount(String folder, int s, int count) async {
    var n = 0;
    for (var a = 1; a <= count; a++) {
      final f = await _cacheFile(folder, s, a);
      if (await f.exists() && await f.length() > 2000) n++;
    }
    return n;
  }

  /// تحميل السورة كلها للاستماع من غير إنترنت (٤ آيات في نفس الوقت). بيرجع عدد اللي فشل.
  static Future<int> downloadSurah(String folder, int s, int count, void Function(double) onProgress, {bool Function()? cancelled}) async {
    var done = 0, failed = 0, next = 1;
    Future<void> worker() async {
      while (next <= count) {
        if (cancelled?.call() ?? false) return;
        final a = next++;
        try {
          final f = await _cacheFile(folder, s, a);
          if (!(await f.exists() && await f.length() > 2000)) await _download(folder, s, a);
        } catch (_) {
          failed++;
        }
        done++;
        onProgress(done / count);
      }
    }

    await Future.wait([for (var k = 0; k < 4; k++) worker()]);
    return failed;
  }

  /// يشغّل الآية وينتظر حتى تنتهي. [fraction] لتشغيل جزء من بداية الآية فقط.
  static Future<void> play(String folder, int s, int a, {double speed = 1.0, double? fraction}) async {
    await stop();
    await Opening.stop();
    final c = Completer<void>();
    _cancel = c;

    final cached = await _cacheFile(folder, s, a);
    final hasCache = await cached.exists() && await cached.length() > 2000;
    final tries = <(String, Future<Duration?> Function())>[
      if (hasCache) ('cache', () => _player.setFilePath(cached.path)),
      for (var h = 0; h < _hosts.length; h++) ('stream$h', () => _player.setUrl(url(folder, s, a, h))),
      ('download', () async => _player.setFilePath((await _download(folder, s, a)).path)),
    ];

    Object? err;
    for (final (name, load) in tries) {
      if (c.isCompleted) return;
      try {
        final d = await load().timeout(Duration(seconds: name == 'download' ? 60 : 15));
        if (c.isCompleted) return;
        if (fraction != null && d != null) {
          await _player.setClip(end: Duration(milliseconds: (d.inMilliseconds * fraction).round()));
        }
        await _player.setVolume(1.0);
        await _player.setSpeed(speed);
        final done = _player.processingStateStream.firstWhere((st) => st == ProcessingState.completed);
        unawaited(_player.play());
        // نتأكد إن الصوت بدأ فعلًا (الموضع بيتحرّك)، وإلا نجرّب الطريقة اللي بعدها
        final started = await _player.positionStream
            .firstWhere((p) => p > Duration(milliseconds: 250))
            .then((_) => true)
            .timeout(Duration(seconds: 8), onTimeout: () => false);
        if (c.isCompleted) return;
        if (!started && _player.processingState != ProcessingState.completed) {
          throw Exception('$name: no playback');
        }
        if (!name.startsWith('cache')) _keep(folder, s, a);
        // مهلة أمان: عمر الآية ما تعلّق الجلسة
        final len = (fraction != null && d != null ? d * fraction : d) ?? Duration(seconds: 90);
        final cap = Duration(milliseconds: (len.inMilliseconds / speed).round()) + Duration(seconds: 6);
        await Future.any([done, c.future, Future.delayed(cap)]);
        if (identical(_cancel, c)) _cancel = null;
        await _player.pause();
        lastError = '';
        return;
      } catch (e) {
        err = e;
        try { await _player.stop(); } catch (_) {}
        if (name == 'cache') { try { await cached.delete(); } catch (_) {} }
      }
    }
    if (identical(_cancel, c)) _cancel = null;
    lastError = '$err';
    throw Exception('تعذّر تشغيل التلاوة: $err');
  }

  static Future<void> stop() async {
    final c = _cancel;
    _cancel = null;
    if (c != null && !c.isCompleted) c.complete();
    await _player.stop();
  }
}
