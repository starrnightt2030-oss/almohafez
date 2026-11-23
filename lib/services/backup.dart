import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/progress.dart';
import 'groups.dart';

/// النسخة الاحتياطية: تقدّمك وشهاداتك وإعداداتك محفوظة في السحابة بكود سرّي (من غير حسابات).
/// لو غيّرت موبايلك أو مسحت التطبيق، تكتب الكود وكل حاجة ترجع.
class Backup {
  static CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore.instance.collection('backups');

  static String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = math.Random.secure();
    return List.generate(12, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// الكود معروض بشكل أسهل للقراءة: XXXX-XXXX-XXXX
  static String pretty(String c) => '${c.substring(0, 4)}-${c.substring(4, 8)}-${c.substring(8)}';

  /// يحفظ نسخة دلوقتي (وبيعمل كود لو أول مرة). بيرجع الكود أو null لو فشل.
  static Future<String?> now() async {
    if (!await Groups.init()) return null;
    try {
      final code = Progress.backupCode ?? _newCode();
      await _col.doc(code).set({
        'data': jsonEncode(Progress.snapshot()),
        'updated': FieldValue.serverTimestamp(),
        'v': 1,
      });
      await Progress.setBackupCode(code);
      await Progress.markBackup();
      return code;
    } catch (_) {
      return null;
    }
  }

  /// نسخة تلقائية (لو مفعّلة) — مرة كل ساعة بالكتير.
  static Future<void> auto() async {
    if (Progress.backupCode == null) return;
    final last = Progress.backupAt;
    if (last != null && DateTime.now().difference(last).inMinutes < 60) return;
    await now();
  }

  /// استرجاع بالكود: true لو نجح، false لو الكود غلط، null لو مفيش إنترنت.
  static Future<bool?> restore(String code) async {
    code = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (code.length != 12) return false;
    if (!await Groups.init()) return null;
    try {
      final d = await _col.doc(code).get();
      if (!d.exists) return false;
      final snap = jsonDecode(d.data()!['data'] as String) as Map<String, dynamic>;
      await Progress.setBackupCode(code);
      await Progress.restore(snap);
      await Progress.setBackupCode(code);
      await Progress.markBackup();
      return true;
    } catch (_) {
      return null;
    }
  }
}
