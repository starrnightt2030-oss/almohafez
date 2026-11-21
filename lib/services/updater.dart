import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// التحديث التلقائي (زي رحلة سراج): بنسأل GitHub عن آخر نسخة منشورة.
/// النسخة مابتتنشرش غير بعد ما ملف الـ APK يجهز، فلو رقمها أكبر يبقى التحديث موجود فعلًا.
/// التحميل جوّه التطبيق مع نسبة التقدّم، وبنتأكد إن الملف كامل قبل ما نفتح شاشة التثبيت.
class UpdateInfo {
  final String version;
  final List<String> notes;
  final String url;
  final int size;
  const UpdateInfo(this.version, this.notes, this.url, this.size);
  String get sizeMb => (size / 1048576).toStringAsFixed(1);
}

class Updater {
  static const repo = 'starrnightt2030-oss/almohafez';
  static const apkName = 'almohafez.apk';

  /// رقم النسخة الحالية — بيتحط وقت البناء من release.json
  static const current = String.fromEnvironment('APP_VERSION', defaultValue: '0.0.0');

  static int cmp(String a, String b) {
    List<int> p(String v) => v.split('.').map((x) => int.tryParse(x) ?? 0).toList()..addAll([0, 0, 0]);
    final x = p(a), y = p(b);
    for (var i = 0; i < 3; i++) {
      if (x[i] != y[i]) return x[i] - y[i];
    }
    return 0;
  }

  /// بيرجع التحديث لو فيه نسخة أحدث، وإلا null. أي مشكلة في النت = null (من غير ما نزعج المستخدم)
  static Future<UpdateInfo?> check() async {
    if (!Platform.isAndroid) return null;
    try {
      final r = await http.get(
        Uri.parse('https://api.github.com/repos/$repo/releases/latest'),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final tag = (j['tag_name'] ?? '').toString();
      if (!RegExp(r'^v\d+\.\d+').hasMatch(tag)) return null;
      final v = tag.substring(1);
      if (cmp(v, current) <= 0) return null;
      final assets = (j['assets'] as List? ?? []).cast<Map<String, dynamic>>();
      final a = assets.where((x) => x['name'] == apkName).firstOrNull;
      if (a == null) return null;
      final notes = (j['body'] ?? '')
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.startsWith('•') || l.startsWith('- '))
          .map((l) => l.replaceFirst(RegExp(r'^(•|-)\s*'), ''))
          .where((l) => l.isNotEmpty)
          .toList();
      return UpdateInfo(v, notes, a['browser_download_url'].toString(), (a['size'] as num?)?.toInt() ?? 0);
    } catch (_) {
      return null;
    }
  }

  // «لاحقًا»: مانسألش تاني عن نفس النسخة لمدة ١٢ ساعة
  static const _snoozeKey = 'update_snooze';
  static Future<bool> snoozed(String v) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_snoozeKey) ?? '';
    final i = s.indexOf('|');
    if (i < 0 || s.substring(0, i) != v) return false;
    final t = int.tryParse(s.substring(i + 1)) ?? 0;
    return DateTime.now().millisecondsSinceEpoch - t < 12 * 3600 * 1000;
  }

  static Future<void> snooze(String v) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_snoozeKey, '$v|${DateTime.now().millisecondsSinceEpoch}');
  }

  static Future<File>? _running;

  /// تحميل الـ APK مع التقدّم (من ٠ لـ ١). ضغطتين = تحميل واحد بس
  static Future<File> download(UpdateInfo u, void Function(double f, int got, int total) onProgress) {
    return _running ??= _download(u, onProgress).whenComplete(() => _running = null);
  }

  static Future<File> _download(UpdateInfo u, void Function(double, int, int) onProgress) async {
    final dir = await getTemporaryDirectory();
    // نمسح أي ملف قديم أو ناقص من محاولة قبل كده
    for (final f in dir.listSync()) {
      if (f is File && RegExp(r'almohafez.*\.apk$').hasMatch(f.path)) {
        try { f.deleteSync(); } catch (_) {}
      }
    }
    final file = File('${dir.path}/almohafez-${u.version}.apk');
    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(u.url))).timeout(Duration(seconds: 30));
      if (res.statusCode != 200) throw Exception('http ${res.statusCode}');
      final total = u.size > 0 ? u.size : (res.contentLength ?? 0);
      final sink = file.openWrite();
      var got = 0;
      var last = -1.0;
      try {
        await for (final chunk in res.stream.timeout(Duration(seconds: 60))) {
          sink.add(chunk);
          got += chunk.length;
          if (total > 0) {
            final f = (got / total).clamp(0.0, 1.0);
            if (f - last >= 0.005) {
              last = f;
              onProgress(f, got, total);
            }
          }
        }
      } finally {
        await sink.close();
      }
      final len = await file.length();
      // الملف لازم يكون كامل بالظبط، وإلا شاشة التثبيت تقول «مشكلة في تحليل الحزمة»
      if (len < 3000000 || (u.size > 0 && len != u.size)) {
        try { await file.delete(); } catch (_) {}
        throw Exception('incomplete');
      }
      onProgress(1, len, len);
      return file;
    } finally {
      client.close();
    }
  }

  /// يفتح شاشة التثبيت بتاعة أندرويد (أول مرة أندرويد بيطلب «السماح بالتثبيت من التطبيق ده»)
  static Future<bool> install(File f) async {
    final r = await OpenFilex.open(f.path, type: 'application/vnd.android.package-archive');
    return r.type == ResultType.done;
  }
}
