import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'quran.dart';

class Cert {
  final String kind; // surah | tajweed
  final String title;
  final String name;
  final int hifz;
  final int accuracy;
  final String grade;
  final String date;
  final String code;
  Cert(this.kind, this.title, this.name, this.hifz, this.accuracy, this.grade, this.date, this.code);

  Map<String, dynamic> toJson() => {
        'k': kind, 't': title, 'n': name, 'h': hifz, 'a': accuracy, 'g': grade, 'd': date, 'c': code,
      };
  static Cert fromJson(Map<String, dynamic> j) => Cert(j['k'] as String, j['t'] as String, j['n'] as String,
      j['h'] as int, j['a'] as int, j['g'] as String, j['d'] as String, j['c'] as String);
}

/// كل تقدّم المستخدم محفوظ على الجهاز فقط.
class Progress {
  static late SharedPreferences _p;
  static final Map<int, Set<int>> _mem = {};
  static final Set<String> _days = {};
  static final List<Cert> certs = [];
  static final Map<String, int> tajweed = {};
  static final Map<String, int> tests = {};

  static Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    final m = _p.getString('mem');
    if (m != null) {
      final j = jsonDecode(m) as Map<String, dynamic>;
      j.forEach((k, v) => _mem[int.parse(k)] = (v as List).cast<int>().toSet());
    }
    _days.addAll(_p.getStringList('days') ?? []);
    final c = _p.getString('certs');
    if (c != null) {
      certs.addAll((jsonDecode(c) as List).map((e) => Cert.fromJson(e as Map<String, dynamic>)));
    }
    final t = _p.getString('tajweed');
    if (t != null) (jsonDecode(t) as Map<String, dynamic>).forEach((k, v) => tajweed[k] = v as int);
    final ts = _p.getString('tests');
    if (ts != null) (jsonDecode(ts) as Map<String, dynamic>).forEach((k, v) => tests[k] = v as int);
    _loadExtra();
  }

  static bool isMem(AyahRef r) => _mem[r.s]?.contains(r.a) ?? false;

  static Future<void> markMem(AyahRef r) async {
    (_mem[r.s] ??= <int>{}).add(r.a);
    await _p.setString('mem', jsonEncode(_mem.map((k, v) => MapEntry('$k', v.toList()))));
  }

  static int memInSurah(int s) => _mem[s]?.length ?? 0;
  static int memIn(List<AyahRef> refs) => refs.where(isMem).length;
  static int get memTotal => _mem.values.fold(0, (a, b) => a + b.length);

  static int firstUnmemorized(int s) {
    final n = QuranData.surah(s).count;
    for (var a = 1; a <= n; a++) {
      if (!isMem(AyahRef(s, a))) return a;
    }
    return 1;
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static Future<void> touchToday() async {
    if (_days.add(_key(DateTime.now()))) await _p.setStringList('days', _days.toList());
  }

  static int get streak {
    var d = DateTime.now();
    if (!_days.contains(_key(d))) d = d.subtract(Duration(days: 1));
    var n = 0;
    while (_days.contains(_key(d))) {
      n++;
      d = d.subtract(Duration(days: 1));
    }
    return n;
  }

  static String? get name => _p.getString('name');
  static Future<void> setName(String v) => _p.setString('name', v.trim());

  /// المقدمة بتظهر مرة واحدة بس (المستخدم القديم اللي عنده تقدّم مايشوفهاش)
  static bool get introSeen => (_p.getBool('intro') ?? false) || memTotal > 0 || xp > 0;
  static Future<void> setIntroSeen() => _p.setBool('intro', true);

  /// المصحِّح الذكي: صارم = أي حرف مختلف غلطة (حتى في الكلمات الطويلة)
  static bool get strictRecite => _p.getBool('strict') ?? false;
  static Future<void> setStrictRecite(bool v) => _p.setBool('strict', v);

  /// استخدام المصحِّح الذكي (على الجهاز) بدل التعرف من Google
  static bool get smartEar => _p.getBool('smartEar') ?? true;
  static Future<void> setSmartEar(bool v) => _p.setBool('smartEar', v);

  static String get reciter => _p.getString('reciter') ?? 'Husary_Muallim_128kbps';
  static Future<void> setReciter(String v) => _p.setString('reciter', v);

  /// صوت القراءة الآلية المختار (اسم الصوت في محرّك الكلام بالموبايل)
  static String? get ttsVoice => _p.getString('tts_voice');
  static Future<void> setTtsVoice(String v) => _p.setString('tts_voice', v);

  static AyahRef? get last {
    final s = _p.getInt('lastS');
    final a = _p.getInt('lastA');
    if (s == null || a == null) return null;
    return AyahRef(s, a);
  }

  static Future<void> setLast(AyahRef r) async {
    await _p.setInt('lastS', r.s);
    await _p.setInt('lastA', r.a);
  }

  static Future<void> addCert(Cert c) async {
    certs.removeWhere((x) => x.kind == c.kind && x.title == c.title);
    certs.add(c);
    await _p.setString('certs', jsonEncode(certs.map((e) => e.toJson()).toList()));
  }

  static Future<void> setTajweed(int level, int score) async {
    final k = '$level';
    if ((tajweed[k] ?? 0) < score) tajweed[k] = score;
    await _p.setString('tajweed', jsonEncode(tajweed));
  }

  static Future<void> setTest(int surah, int score) async {
    final k = '$surah';
    if ((tests[k] ?? 0) < score) tests[k] = score;
    await _p.setString('tests', jsonEncode(tests));
  }

  static int? placement() => _p.getInt('placement');
  static Future<void> setPlacement(int juzCount) => _p.setInt('placement', juzCount);

  // ===== الدروس والاختبارات =====
  static Map<String, int> _lessons = {};
  static Map<String, int> _units = {};
  static Set<String> _fav = {};

  static void _loadExtra() {
    final l = _p.getString('lessons');
    if (l != null) _lessons = (jsonDecode(l) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    final u = _p.getString('units');
    if (u != null) _units = (jsonDecode(u) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    _fav = (_p.getStringList('fav') ?? []).toSet();
  }

  static bool lessonPassed(String id) => _lessons.containsKey(id);
  static int? lessonScore(String id) => _lessons[id];
  static Future<void> passLesson(String id, int score) async {
    if ((_lessons[id] ?? -1) < score) _lessons[id] = score;
    await _p.setString('lessons', jsonEncode(_lessons));
  }

  static int? unitScore(String id) => _units[id];
  static Future<void> passUnit(String id, int score) async {
    if ((_units[id] ?? -1) < score) _units[id] = score;
    await _p.setString('units', jsonEncode(_units));
  }

  static bool practiced(AyahRef r) => (_p.getStringList('practiced') ?? []).contains('${r.s}:${r.a}');
  static Future<void> markPracticed(AyahRef r) async {
    final l = (_p.getStringList('practiced') ?? []).toSet()..add('${r.s}:${r.a}');
    await _p.setStringList('practiced', l.toList());
  }

  static bool isFav(String key) => _fav.contains(key);
  static List<String> get favorites => _fav.toList();
  static Future<void> toggleFav(String key) async {
    if (!_fav.remove(key)) _fav.add(key);
    await _p.setStringList('fav', _fav.toList());
  }

  // ===== النقاط =====
  static int get xp => _p.getInt('xp') ?? 0;
  static Future<void> addXp(int v) => _p.setInt('xp', xp + v);
  static int get level => 1 + xp ~/ 250;
  static double get levelProgress => (xp % 250) / 250;
  static int get bestArena => _p.getInt('bestArena') ?? 0;
  static Future<void> setBestArena(int v) async {
    if (v > bestArena) await _p.setInt('bestArena', v);
  }

  // ===== الإعدادات =====
  static bool get voiceOn => _p.getBool('voiceOn') ?? true;
  static Future<void> setVoiceOn(bool v) => _p.setBool('voiceOn', v);
  static double get voiceRate => _p.getDouble('voiceRate') ?? 0.45;
  static Future<void> setVoiceRate(double v) => _p.setDouble('voiceRate', v);
  static final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);
  static int get themeIndex => _p.getInt('theme') ?? 0;
  static Future<void> setTheme(int i) async {
    await _p.setInt('theme', i);
    themeNotifier.value = i;
  }

  static bool get tajweedColors => _p.getBool('tjColors') ?? true;
  static Future<void> setTajweedColors(bool v) => _p.setBool('tjColors', v);
}
