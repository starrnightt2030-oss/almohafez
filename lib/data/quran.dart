import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AyahRef {
  final int s;
  final int a;
  const AyahRef(this.s, this.a);
  @override
  bool operator ==(Object other) => other is AyahRef && other.s == s && other.a == a;
  @override
  int get hashCode => s * 1000 + a;
}

class Surah {
  final int number;
  final String name;
  final String type;
  final List<String> uthmani;
  final List<String> simple;
  Surah(this.number, this.name, this.type, this.uthmani, this.simple);
  int get count => simple.length;
}

/// بيانات المصحف (رواية حفص) مضمّنة في التطبيق وتعمل دون اتصال.
class QuranData {
  static final List<Surah> surahs = [];
  static final List<AyahRef> juzStarts = [];
  static final List<AyahRef> rubStarts = [];
  static final List<int> _offsets = [];
  static int total = 0;

  static Future<void> load() async {
    if (surahs.isNotEmpty) return;
    final raw = await rootBundle.loadString('assets/quran/quran.json');
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final ss = j['s'] as List;
    var off = 0;
    for (var i = 0; i < ss.length; i++) {
      final m = ss[i] as Map<String, dynamic>;
      final ayat = (m['a'] as List).cast<List>();
      surahs.add(Surah(
        i + 1,
        m['n'] as String,
        m['r'] as String,
        ayat.map((x) => x[0] as String).toList(),
        ayat.map((x) => x[1] as String).toList(),
      ));
      _offsets.add(off);
      off += ayat.length;
    }
    total = off;
    for (final x in (j['juz'] as List)) {
      juzStarts.add(AyahRef(x[0] as int, x[1] as int));
    }
    for (final x in (j['rub'] as List)) {
      rubStarts.add(AyahRef(x[0] as int, x[1] as int));
    }
  }

  static Surah surah(int s) => surahs[s - 1];

  static int g(AyahRef r) => _offsets[r.s - 1] + r.a - 1;

  static AyahRef fromG(int g) {
    var lo = 0, hi = _offsets.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_offsets[mid] <= g) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return AyahRef(lo + 1, g - _offsets[lo] + 1);
  }

  static List<AyahRef> _between(AyahRef from, AyahRef? toExclusive) {
    final a = g(from);
    final b = toExclusive == null ? total : g(toExclusive);
    return [for (var i = a; i < b; i++) fromG(i)];
  }

  static List<AyahRef> surahAyahs(int s) => [for (var a = 1; a <= surah(s).count; a++) AyahRef(s, a)];

  static List<AyahRef> juzAyahs(int juz) =>
      _between(juzStarts[juz - 1], juz < juzStarts.length ? juzStarts[juz] : null);

  static List<AyahRef> rubAyahs(int rub) =>
      _between(rubStarts[rub - 1], rub < rubStarts.length ? rubStarts[rub] : null);

  static List<AyahRef> hizbAyahs(int hizb) {
    final start = rubStarts[(hizb - 1) * 4];
    final endIdx = hizb * 4;
    return _between(start, endIdx < rubStarts.length ? rubStarts[endIdx] : null);
  }

  static List<AyahRef> all() => [for (var i = 0; i < total; i++) fromG(i)];

  static int juzOf(AyahRef r) {
    final x = g(r);
    var j = 1;
    for (var i = 0; i < juzStarts.length; i++) {
      if (g(juzStarts[i]) <= x) j = i + 1;
    }
    return j;
  }

  /// كلمات الآية بالرسم البسيط (تُستخدم للمقارنة بالتلاوة).
  static List<String> simpleWords(AyahRef r) => surah(r.s).simple[r.a - 1].split(' ');

  /// كلمات الآية للعرض: بالرسم العثماني إن تطابق عدد الكلمات، وإلا بالرسم البسيط المشكول.
  static List<String> displayWords(AyahRef r) {
    final su = surah(r.s);
    final u = su.uthmani[r.a - 1].split(' ');
    final s = su.simple[r.a - 1].split(' ');
    return u.length == s.length ? u : s;
  }

  static String uthmaniText(AyahRef r) => surah(r.s).uthmani[r.a - 1];
}

class TajweedSpan {
  final int rule;
  final int start;
  final int end;
  const TajweedSpan(this.rule, this.start, this.end);
}

class TajweedAyah {
  final String text;
  final List<TajweedSpan> spans;
  TajweedAyah(this.text, this.spans);

  static const _pause = 'ۖۗۘۙۚۛۜ۩';

  /// الكلمات مع مواضعها في النص (بدون علامات الوقف).
  List<(int, int)> wordRanges() {
    final out = <(int, int)>[];
    var i = 0;
    while (i < text.length) {
      while (i < text.length && text[i] == ' ') {
        i++;
      }
      if (i >= text.length) break;
      final s = i;
      while (i < text.length && text[i] != ' ') {
        i++;
      }
      final w = text.substring(s, i);
      if (!w.split('').every((c) => _pause.contains(c))) out.add((s, i));
    }
    return out;
  }
}

/// نص المصحف الملوّن بأحكام التجويد (يُحمّل عند الحاجة).
class TajweedData {
  static List<TajweedAyah>? _a;
  static List<List<String>>? _tafsir;

  static Future<void> load() async {
    if (_a != null) return;
    final j = jsonDecode(await rootBundle.loadString('assets/quran/tajweed.json')) as Map<String, dynamic>;
    _a = (j['a'] as List).map((e) {
      final x = e as List;
      return TajweedAyah(
        x[0] as String,
        (x[1] as List).map((s) {
          final t = s as List;
          return TajweedSpan(t[0] as int, t[1] as int, t[2] as int);
        }).toList(),
      );
    }).toList();
  }

  static bool get ready => _a != null;

  static TajweedAyah? of(AyahRef r) => _a == null ? null : _a![QuranData.g(r)];

  static Future<String> tafsir(AyahRef r) async {
    if (_tafsir == null) {
      final j = jsonDecode(await rootBundle.loadString('assets/quran/tafsir.json')) as List;
      _tafsir = j.map((s) => (s as List).cast<String>()).toList();
    }
    return _tafsir![r.s - 1][r.a - 1];
  }
}
