import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as so;

/// «المصحِّح الذكي»: التعرف على التلاوة على الموبايل نفسه (بدون إنترنت وبدون Google).
///
/// - نموذج quran-asr-tiny (مدرّب على تلاوات القرآن، ١٩ م.ب) بيطلع حروف الآية كما نُطقت.
/// - Silero VAD بيعرف إمتى بدأت وإمتى سكتّ، فالميكروفون بيشتغل وحده بعد الشيخ ويقفل وحده.
/// - كل الشغل التقيل في Isolate منفصل عشان الواجهة ماتهنّجش.
class QuranEar {
  static const _release = 'https://github.com/starrnightt2030-oss/almohafez/releases/download/asr-models';
  static const _hf = 'https://huggingface.co/Abdou/quran-asr-tiny/resolve/main';

  /// الملف ← (الحجم بالبايت، الرابط الاحتياطي)
  static const files = <String, (int, String?)>{
    'quran-asr-tiny.int8.onnx': (18850806, '$_hf/model.int8.onnx'),
    'quran-asr-tokens.txt': (180, '$_hf/tokens.txt'),
    'silero_vad.onnx': (643854, null),
  };
  static int get totalBytes => files.values.fold(0, (a, b) => a + b.$1);

  /// تقدّم التحميل (null = مفيش تحميل شغال)
  static final progress = ValueNotifier<double?>(null);
  static bool _installed = false;
  static bool get installed => _installed;
  static Future<void>? _downloading;

  static Future<Directory> _dir() async {
    final d = Directory('${(await getApplicationSupportDirectory()).path}/asr');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// يتأكد إن الملفات موجودة وكاملة.
  static Future<bool> checkInstalled() async {
    try {
      final d = await _dir();
      for (final e in files.entries) {
        final f = File('${d.path}/${e.key}');
        if (!await f.exists() || await f.length() != e.value.$1) return _installed = false;
      }
      return _installed = true;
    } catch (_) {
      return _installed = false;
    }
  }

  /// يحمّل النماذج مرة واحدة (لو مش موجودة). آمن لو اتنادى أكتر من مرة.
  static Future<bool> download() {
    _downloading ??= _download().whenComplete(() => _downloading = null);
    return _downloading!.then((_) => _installed);
  }

  static Future<void> _download() async {
    if (await checkInstalled()) return;
    final d = await _dir();
    final client = http.Client();
    var done = 0;
    progress.value = 0;
    try {
      for (final e in files.entries) {
        final f = File('${d.path}/${e.key}');
        if (await f.exists() && await f.length() == e.value.$1) {
          done += e.value.$1;
          continue;
        }
        var ok = false;
        for (final url in ['$_release/${e.key}', if (e.value.$2 != null) e.value.$2!]) {
          ok = await _fetch(client, url, f, e.value.$1, (n) {
            progress.value = (done + n) / totalBytes;
          });
          if (ok) break;
        }
        if (!ok) return;
        done += e.value.$1;
        progress.value = done / totalBytes;
      }
      await checkInstalled();
    } finally {
      client.close();
      progress.value = null;
    }
  }

  static Future<bool> _fetch(http.Client c, String url, File out, int size, void Function(int) onBytes) async {
    final part = File('${out.path}.part');
    try {
      final res = await c.send(http.Request('GET', Uri.parse(url))).timeout(Duration(seconds: 25));
      if (res.statusCode != 200) return false;
      final sink = part.openWrite();
      var n = 0;
      await for (final chunk in res.stream.timeout(Duration(seconds: 30))) {
        sink.add(chunk);
        n += chunk.length;
        onBytes(n);
      }
      await sink.close();
      if (await part.length() != size) {
        await part.delete();
        return false;
      }
      if (await out.exists()) await out.delete();
      await part.rename(out.path);
      return true;
    } catch (_) {
      try {
        if (await part.exists()) await part.delete();
      } catch (_) {}
      return false;
    }
  }

  // ───────────── الاستماع ─────────────

  static Isolate? _iso;
  static SendPort? _port;
  static ReceivePort? _rx;
  static final _events = StreamController<Object>.broadcast();
  static AudioRecorder? _rec;
  static StreamSubscription<Uint8List>? _micSub;
  static Future<bool>? _starting;

  /// يجهّز الـ Isolate والنماذج (أول مرة بس، حوالي نص ثانية).
  static Future<bool> warmUp() {
    if (_port != null) return Future.value(true);
    _starting ??= _spawn().whenComplete(() => _starting = null);
    return _starting!;
  }

  static Future<bool> _spawn() async {
    if (!_installed && !await checkInstalled()) return false;
    try {
      final d = await _dir();
      _rx = ReceivePort();
      final ready = Completer<bool>();
      _rx!.listen((m) {
        if (m is SendPort) {
          _port = m;
          if (!ready.isCompleted) ready.complete(true);
        } else if (m is _Failed) {
          if (!ready.isCompleted) ready.complete(false);
        } else if (m is Object) {
          _events.add(m);
        }
      });
      _iso = await Isolate.spawn(_worker, _Init(_rx!.sendPort, d.path));
      final ok = await ready.future.timeout(Duration(seconds: 20), onTimeout: () => false);
      if (!ok) _kill();
      return ok;
    } catch (_) {
      _kill();
      return false;
    }
  }

  static void _kill() {
    _iso?.kill(priority: Isolate.immediate);
    _iso = null;
    _port = null;
    _rx?.close();
    _rx = null;
  }

  static bool _active = false;
  static bool get isListening => _active;

  /// يسمع آية واحدة لحد ما القارئ يخلّص.
  ///
  /// [onLive] بالنص أول بأول (للمتابعة الحية)، [onSpeech] لما يبدأ/يسكت،
  /// [isComplete] بتقول لو النص وصل لآخر الآية فننهي فورًا،
  /// [onDone] بالنص النهائي (فاضي لو ماتكلمش).
  static Future<bool> listen({
    required void Function(String text) onLive,
    required void Function(String text) onDone,
    void Function(bool speaking)? onSpeech,
    bool Function(String text)? isComplete,
    Duration endSilence = const Duration(milliseconds: 1600),
    Duration noVoice = const Duration(seconds: 9),
    Duration maxLen = const Duration(seconds: 120),
  }) async {
    await cancel();
    if (!await warmUp()) return false;
    _rec ??= AudioRecorder();
    if (!await _rec!.hasPermission()) return false;

    final finals = <String>[];
    var partial = '';
    var speaking = false;
    var heardAny = false;
    var pending = 0; // مقاطع لسه بتتفك
    Timer? endTimer;
    final started = DateTime.now();
    var finished = false;
    var force = false;
    StreamSubscription<Object>? evSub;

    String text() => [...finals, if (partial.isNotEmpty) partial].join(' ').trim();

    Future<void> finish() async {
      if (finished) return;
      finished = true;
      _forceEnd = null;
      _abort = null;
      endTimer?.cancel();
      await evSub?.cancel();
      await _stopMic();
      _active = false;
      onDone(finals.join(' ').trim().isEmpty ? partial.trim() : finals.join(' ').trim());
    }

    void armEnd() {
      endTimer?.cancel();
      if (speaking || pending > 0) return;
      final wait = force ? Duration(milliseconds: 120) : (heardAny ? endSilence : noVoice);
      endTimer = Timer(wait, finish);
    }

    _port!.send(_Reset());
    _abort = () {
      finished = true;
      endTimer?.cancel();
      evSub?.cancel();
    };
    _forceEnd = () {
      force = true;
      _stopMic();
      _port?.send(_Flush());
      armEnd();
    };
    evSub = _events.stream.listen((m) {
      if (finished) return;
      if (m is _Speech) {
        speaking = m.on;
        if (m.on) heardAny = true;
        onSpeech?.call(m.on);
        armEnd();
      } else if (m is _Partial) {
        partial = m.text;
        onLive(text());
      } else if (m is _SegStart) {
        pending++;
      } else if (m is _Final) {
        pending = pending > 0 ? pending - 1 : 0;
        if (m.text.trim().isNotEmpty) finals.add(m.text.trim());
        partial = '';
        final t = text();
        onLive(t);
        if (isComplete != null && t.isNotEmpty && isComplete(t) && !speaking) {
          finish();
          return;
        }
        armEnd();
      }
      if (DateTime.now().difference(started) > maxLen) finish();
    });

    try {
      final stream = await _rec!.startStream(RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ));
      _active = true;
      final carry = <int>[];
      _micSub = stream.listen((data) {
        if (finished || _port == null) return;
        carry.addAll(data);
        final n = carry.length ~/ 2;
        if (n == 0) return;
        final f = Float32List(n);
        for (var i = 0; i < n; i++) {
          var v = carry[2 * i] | (carry[2 * i + 1] << 8);
          if (v >= 0x8000) v -= 0x10000;
          f[i] = v / 32768.0;
        }
        carry.removeRange(0, n * 2);
        _port!.send(_Audio(f));
      }, onError: (_) => finish());
      armEnd();
      return true;
    } catch (_) {
      await finish();
      return false;
    }
  }

  static Future<void> _stopMic() async {
    await _micSub?.cancel();
    _micSub = null;
    try {
      if (await _rec?.isRecording() ?? false) await _rec!.stop();
    } catch (_) {}
  }

  /// إيقاف فوري (من غير نتيجة).
  static void Function()? _abort;

  static Future<void> cancel() async {
    _abort?.call();
    _abort = null;
    _forceEnd = null;
    _active = false;
    await _stopMic();
    _port?.send(_Reset());
  }

  static void Function()? _forceEnd;

  /// إنهاء الاستماع يدويًا: بيكمّل فك آخر جزء ويرجّع النتيجة فورًا.
  static void finishNow() => _forceEnd?.call();
}

// ───────────── رسائل الـ Isolate ─────────────

class _Init {
  final SendPort out;
  final String dir;
  const _Init(this.out, this.dir);
}

class _Failed {
  final String error;
  const _Failed(this.error);
}

class _Audio {
  final Float32List samples;
  const _Audio(this.samples);
}

class _Reset {
  const _Reset();
}

class _Flush {
  const _Flush();
}

class _Speech {
  final bool on;
  const _Speech(this.on);
}

class _SegStart {
  const _SegStart();
}

class _Partial {
  final String text;
  const _Partial(this.text);
}

class _Final {
  final String text;
  const _Final(this.text);
}

/// الـ Isolate: اكتشاف الصوت + التعرف (جزئي أثناء الكلام، ونهائي لكل مقطع).
Future<void> _worker(_Init init) async {
  final out = init.out;
  late final so.OfflineRecognizer rec;
  late final so.VoiceActivityDetector vad;
  try {
    await so.initBindingsAsync();
    rec = so.OfflineRecognizer(so.OfflineRecognizerConfig(
      model: so.OfflineModelConfig(
        zipformerCtc: so.OfflineZipformerCtcModelConfig(model: '${init.dir}/quran-asr-tiny.int8.onnx'),
        tokens: '${init.dir}/quran-asr-tokens.txt',
        numThreads: 2,
        debug: false,
      ),
    ));
    vad = so.VoiceActivityDetector(
      config: so.VadModelConfig(
        sileroVad: so.SileroVadModelConfig(
          model: '${init.dir}/silero_vad.onnx',
          threshold: 0.45,
          minSilenceDuration: 0.55,
          minSpeechDuration: 0.2,
          windowSize: 512,
          maxSpeechDuration: 25,
        ),
        numThreads: 1,
        debug: false,
      ),
      bufferSizeInSeconds: 120,
    );
  } catch (e) {
    out.send(_Failed('$e'));
    return;
  }

  String decode(Float32List s) {
    if (s.length < 1600) return '';
    final st = rec.createStream();
    st.acceptWaveform(samples: s, sampleRate: 16000);
    rec.decode(st);
    final t = rec.getResult(st).text;
    st.free();
    return t.trim();
  }

  const win = 512;
  final buf = <double>[]; // بقايا أقل من نافذة
  final cur = <double>[]; // الكلام الحالي (للتعرف الجزئي)
  final pre = <double>[]; // ثلث ثانية قبل بداية الكلام
  var speaking = false;
  var lastPartialAt = 0;

  void drain() {
    while (!vad.isEmpty()) {
      final seg = vad.front().samples;
      vad.pop();
      out.send(_SegStart());
      out.send(_Final(decode(seg)));
      cur.clear();
      lastPartialAt = 0;
    }
  }

  final port = ReceivePort();
  out.send(port.sendPort);
  port.listen((m) {
    if (m is _Reset) {
      vad.reset();
      buf.clear();
      cur.clear();
      pre.clear();
      speaking = false;
      lastPartialAt = 0;
    } else if (m is _Flush) {
      vad.flush();
      drain();
      if (speaking) {
        speaking = false;
        out.send(_Speech(false));
      }
    } else if (m is _Audio) {
      buf.addAll(m.samples);
      while (buf.length >= win) {
        final chunk = Float32List.fromList(buf.sublist(0, win));
        buf.removeRange(0, win);
        vad.acceptWaveform(chunk);
        final now = vad.isDetected();
        if (now != speaking) {
          speaking = now;
          out.send(_Speech(now));
          if (now) {
            cur
              ..clear()
              ..addAll(pre);
          }
        }
        if (speaking) {
          cur.addAll(chunk);
          // تعرف جزئي كل ~٠٫٨ ثانية كلام عشان الكلمات تخضرّ وأنت بتقرأ
          if (cur.length - lastPartialAt >= 12800) {
            lastPartialAt = cur.length;
            out.send(_Partial(decode(Float32List.fromList(cur))));
          }
        } else {
          pre.addAll(chunk);
          if (pre.length > 5120) pre.removeRange(0, pre.length - 5120);
        }
        drain();
      }
    }
  });
}
