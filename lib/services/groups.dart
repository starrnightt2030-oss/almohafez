import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import 'firebase_config.dart';
import '../theme.dart' show ar;

/// خطة المجموعة: سورة (من آية لآية) أو جزء، ومدة بالأيام.
class GroupPlan {
  final String type; // surah | juz
  final int a; // رقم السورة أو الجزء
  final int from, to; // للسورة
  const GroupPlan(this.type, this.a, {this.from = 1, this.to = 0});

  List<AyahRef> get ayahs {
    if (type == 'juz') return QuranData.juzAyahs(a);
    final all = QuranData.surahAyahs(a);
    final end = to <= 0 ? all.length : to;
    return all.where((r) => r.a >= from && r.a <= end).toList();
  }

  String get title {
    if (type == 'juz') return 'الجزء ${ar(a)}';
    final su = QuranData.surah(a);
    final end = to <= 0 ? su.count : to;
    return from == 1 && end == su.count ? 'سورة ${su.name}' : 'سورة ${su.name} (${ar(from)}–${ar(end)})';
  }

  Map<String, dynamic> toJson() => {'type': type, 'a': a, 'from': from, 'to': to};
  factory GroupPlan.fromJson(Map<String, dynamic> j) =>
      GroupPlan(j['type'] as String, (j['a'] as num).toInt(), from: (j['from'] as num?)?.toInt() ?? 1, to: (j['to'] as num?)?.toInt() ?? 0);
}

class Member {
  final String uid, name;
  final int done; // آيات الخطة المحفوظة
  final int streak;
  final int? finalScore;
  final DateTime? lastActive;
  const Member(this.uid, this.name, this.done, this.streak, this.finalScore, this.lastActive);

  factory Member.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data() ?? {};
    return Member(
      d.id,
      (j['name'] as String?) ?? 'عضو',
      (j['done'] as num?)?.toInt() ?? 0,
      (j['streak'] as num?)?.toInt() ?? 0,
      (j['final'] as num?)?.toInt(),
      (j['active'] as Timestamp?)?.toDate(),
    );
  }

  /// النقاط (من ١٠٠): الحفظ ٦٠٪ + الاختبار النهائي ٣٠٪ + الالتزام ١٠٪
  int points(int total) {
    final p = total == 0 ? 0.0 : done / total;
    final f = (finalScore ?? 0) / 100;
    final s = math.min(streak, 14) / 14;
    return (p * 60 + f * 30 + s * 10).round();
  }
}

class Group {
  final String code, name, owner;
  final GroupPlan plan;
  final DateTime start, end;
  final List<String> votes;
  final int memberCount;
  const Group(this.code, this.name, this.owner, this.plan, this.start, this.end, this.votes, this.memberCount);

  factory Group.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final j = d.data()!;
    return Group(
      d.id,
      j['name'] as String,
      j['owner'] as String,
      GroupPlan.fromJson(Map<String, dynamic>.from(j['plan'] as Map)),
      (j['start'] as Timestamp).toDate(),
      (j['end'] as Timestamp).toDate(),
      List<String>.from((j['votes'] as List?) ?? const []),
      (j['count'] as num?)?.toInt() ?? 1,
    );
  }

  int get totalDays => math.max(1, end.difference(start).inDays);
  int get daysLeft => math.max(0, end.difference(DateTime.now()).inHours ~/ 24 + (end.isAfter(DateTime.now()) ? 1 : 0));
  bool get ended => DateTime.now().isAfter(end);
  int get dailyTarget => (plan.ayahs.length / totalDays).ceil();
  /// المفروض يكون اتحفظ كام لحد النهارده
  int get expectedNow {
    final d = math.min(totalDays, DateTime.now().difference(start).inDays + 1);
    return math.min(plan.ayahs.length, d * dailyTarget);
  }
}

/// المجموعات على Firebase (مجاني): كود دعوة من ٦ حروف، تقدّم الأعضاء، تمديد بالتصويت، اختبار نهائي وترتيب.
class Groups {
  static bool get available => FirebaseConfig.apiKey.isNotEmpty;
  static bool _ready = false;
  static String? get uid => _ready ? FirebaseAuth.instance.currentUser?.uid : null;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _groups => _db.collection('groups');

  static Future<bool> init() async {
    if (!available) return false;
    if (_ready) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: FirebaseConfig.apiKey,
            appId: FirebaseConfig.appId,
            messagingSenderId: FirebaseConfig.senderId,
            projectId: FirebaseConfig.projectId,
            storageBucket: FirebaseConfig.bucket,
          ),
        );
      }
      if (FirebaseAuth.instance.currentUser == null) await FirebaseAuth.instance.signInAnonymously();
      _ready = FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  // أكواد مجموعاتي محفوظة على الجهاز
  static Future<List<String>> myCodes() async => (await SharedPreferences.getInstance()).getStringList('groups') ?? [];
  static Future<void> _saveCodes(List<String> c) async => (await SharedPreferences.getInstance()).setStringList('groups', c);

  static String _newCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = math.Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String get _myName {
    final n = Progress.name;
    return (n == null || n.trim().isEmpty) ? 'حافظ' : n.trim();
  }

  /// إنشاء مجموعة جديدة؛ بيرجع الكود.
  static Future<String?> create(String name, GroupPlan plan, int days) async {
    if (!await init()) return null;
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _newCode();
      final ref = _groups.doc(code);
      final ok = await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) return false;
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, now.day);
        tx.set(ref, {
          'name': name.trim(),
          'owner': uid,
          'plan': plan.toJson(),
          'start': Timestamp.fromDate(start),
          'end': Timestamp.fromDate(start.add(Duration(days: days))),
          'votes': <String>[],
          'count': 1,
          'created': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (ok) {
        await _joinMember(code);
        final c = await myCodes();
        await _saveCodes([code, ...c.where((x) => x != code)]);
        return code;
      }
    }
    return null;
  }

  /// الانضمام بكود؛ بيرجع null لو الكود غلط.
  static Future<Group?> join(String code) async {
    if (!await init()) return null;
    code = code.trim().toUpperCase();
    final snap = await _groups.doc(code).get();
    if (!snap.exists) return null;
    final g = Group.fromDoc(snap);
    final m = await _groups.doc(code).collection('members').doc(uid).get();
    if (!m.exists) {
      await _joinMember(code);
      await _groups.doc(code).update({'count': FieldValue.increment(1)});
    }
    final c = await myCodes();
    await _saveCodes([code, ...c.where((x) => x != code)]);
    await pushProgress(g);
    return g;
  }

  static Future<void> _joinMember(String code) => _groups.doc(code).collection('members').doc(uid).set({
        'name': _myName,
        'done': 0,
        'streak': Progress.streak,
        'active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  static Future<void> leave(String code) async {
    final c = await myCodes();
    await _saveCodes(c.where((x) => x != code).toList());
    if (!await init()) return;
    try {
      await _groups.doc(code).collection('members').doc(uid).delete();
      await _groups.doc(code).update({'count': FieldValue.increment(-1)});
    } catch (_) {}
  }

  static Stream<Group?> watch(String code) =>
      _groups.doc(code).snapshots().map((s) => s.exists ? Group.fromDoc(s) : null);

  static Stream<List<Member>> members(String code) =>
      _groups.doc(code).collection('members').snapshots().map((q) => q.docs.map(Member.fromDoc).toList());

  static Future<Group?> fetch(String code) async {
    if (!await init()) return null;
    try {
      final s = await _groups.doc(code).get();
      return s.exists ? Group.fromDoc(s) : null;
    } catch (_) {
      return null;
    }
  }

  /// يرفع تقدّمي في خطة المجموعة (من الحفظ المحلي).
  static Future<void> pushProgress(Group g) async {
    if (!await init()) return;
    final done = g.plan.ayahs.where(Progress.isMem).length;
    try {
      await _groups.doc(g.code).collection('members').doc(uid).set({
        'name': _myName,
        'done': done,
        'streak': Progress.streak,
        'active': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// رفع تقدّمي في كل مجموعاتي (بعد جلسة حفظ مثلًا).
  static Future<void> pushAll() async {
    if (!available) return;
    for (final c in await myCodes()) {
      final g = await fetch(c);
      if (g != null) await pushProgress(g);
    }
  }

  /// تصويت على تمديد المدة ٣ أيام؛ لو أكتر من نص الأعضاء وافقوا بيتمدّ فورًا.
  static Future<bool> voteExtend(Group g) async {
    if (!await init()) return false;
    final ref = _groups.doc(g.code);
    return _db.runTransaction<bool>((tx) async {
      final s = await tx.get(ref);
      final cur = Group.fromDoc(s);
      final votes = {...cur.votes, uid!};
      if (votes.length * 2 > cur.memberCount) {
        tx.update(ref, {'end': Timestamp.fromDate(cur.end.add(Duration(days: 3))), 'votes': <String>[]});
        return true;
      }
      tx.update(ref, {'votes': votes.toList()});
      return false;
    });
  }

  static Future<void> submitFinal(Group g, int pct) async {
    if (!await init()) return;
    final ref = _groups.doc(g.code).collection('members').doc(uid);
    final cur = await ref.get();
    final old = (cur.data()?['final'] as num?)?.toInt() ?? 0;
    await ref.set({'final': math.max(old, pct), 'active': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
}
