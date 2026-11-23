import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// حزمة الصوت: شرح الدروس والأحاديث بصوت المعلّم. بتتحمّل مرة واحدة في الخلفية
/// (بدل ما تكبّر حجم التطبيق وكل تحديث)، ولما تنزل تسجيلات جديدة بيتحمّل الجديد بس.
class VoicePack {
  static const _base = 'https://raw.githubusercontent.com/starrnightt2030-oss/almohafez/audio-work/pack';
  static final progress = ValueNotifier<double?>(null);
  static Directory? _dir;
  static final Set<String> _have = {};
  static Future<void>? _job;

  static Future<Directory> _root() async {
    _dir ??= Directory('${(await getApplicationSupportDirectory()).path}/voicepack');
    if (!await _dir!.exists()) await _dir!.create(recursive: true);
    return _dir!;
  }

  /// يقرأ الملفات المتحمّلة (بيتنادى مع تشغيل الصوت).
  static Future<void> load() async {
    try {
      final d = await _root();
      final f = File('${d.path}/have.json');
      if (await f.exists()) _have.addAll(List<String>.from(jsonDecode(await f.readAsString()) as List));
    } catch (_) {}
  }

  /// مسار الملف المتحمّل لو موجود (assets/audio/lessons/x.mp3 ← ملف على الجهاز).
  static String? file(String assetPath) {
    if (_dir == null || !_have.contains(assetPath)) return null;
    final p = '${_dir!.path}/$assetPath';
    if (!File(p).existsSync()) {
      _have.remove(assetPath);
      return null;
    }
    return p;
  }

  static int get count => _have.length;

  static final Map<String, Future<String?>> _fetching = {};

  /// يحمّل ملف واحد فورًا لو مش موجود (لما الدرس يتفتح قبل ما الحزمة كلها تنزل).
  static Future<String?> fetch(String assetPath) async {
    final have = file(assetPath);
    if (have != null) return have;
    return _fetching[assetPath] ??= _fetchOne(assetPath).whenComplete(() => _fetching.remove(assetPath));
  }

  static Future<String?> _fetchOne(String assetPath) async {
    try {
      final d = await _root();
      final r = await http.get(Uri.parse('$_base/${Uri.encodeFull(assetPath)}')).timeout(Duration(seconds: 25));
      if (r.statusCode != 200 || r.bodyBytes.length < 1000) return null;
      final out = File('${d.path}/$assetPath');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(r.bodyBytes, flush: true);
      _have.add(assetPath);
      unawaited(File('${d.path}/have.json').writeAsString(jsonEncode(_have.toList())).catchError((_) => File('')));
      return out.path;
    } catch (_) {
      return null;
    }
  }

  /// يحمّل الناقص من الحزمة. آمن لو اتنادى أكتر من مرة.
  static Future<void> sync() {
    _job ??= _sync().whenComplete(() => _job = null);
    return _job!;
  }

  static Future<void> _sync() async {
    final c = http.Client();
    try {
      final d = await _root();
      await load();
      final res = await c.get(Uri.parse('$_base/manifest.json')).timeout(Duration(seconds: 20));
      if (res.statusCode != 200) return;
      final m = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final files = (m['files'] as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as List)));
      final sigFile = File('${d.path}/sigs.json');
      final sigs = await sigFile.exists() ? Map<String, String>.from(jsonDecode(await sigFile.readAsString()) as Map) : <String, String>{};
      final todo = files.entries.where((e) => !_have.contains(e.key) || sigs[e.key] != '${e.value[1]}').toList();
      if (todo.isEmpty) return;
      final total = todo.fold<int>(0, (a, e) => a + (e.value[0] as num).toInt());
      var done = 0;
      progress.value = 0;
      var i = 0;
      Future<void> worker() async {
        while (i < todo.length) {
          final e = todo[i++];
          try {
            final r = await c.get(Uri.parse('$_base/${Uri.encodeFull(e.key)}')).timeout(Duration(seconds: 40));
            if (r.statusCode == 200 && r.bodyBytes.length == (e.value[0] as num).toInt()) {
              final out = File('${d.path}/${e.key}');
              await out.parent.create(recursive: true);
              await out.writeAsBytes(r.bodyBytes, flush: true);
              _have.add(e.key);
              sigs[e.key] = '${e.value[1]}';
              if (_have.length % 40 == 0) {
                await File('${d.path}/have.json').writeAsString(jsonEncode(_have.toList()));
                await sigFile.writeAsString(jsonEncode(sigs));
              }
            }
          } catch (_) {}
          done += (e.value[0] as num).toInt();
          progress.value = done / total;
        }
      }

      await Future.wait([for (var k = 0; k < 4; k++) worker()]);
      await File('${d.path}/have.json').writeAsString(jsonEncode(_have.toList()));
      await sigFile.writeAsString(jsonEncode(sigs));
    } catch (_) {
    } finally {
      c.close();
      progress.value = null;
    }
  }
}
