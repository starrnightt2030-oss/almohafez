import 'dart:math' as math;
import '../data/quran.dart';
import 'tajweed_rules.dart';

/// سؤال عام: نصي، أو على موضع من آية.
class QItem {
  final String q;
  final List<String> options;
  final int answer;
  final String why;
  final AyahRef? ref;
  final (int, int)? focus;
  /// مسار تسجيل السؤال والتوضيح بدون اللاحقة (مثل assets/audio/quiz/t01_1_1).
  final String? audio;
  QItem(this.q, this.options, this.answer, this.why, {this.ref, this.focus, this.audio});

  /// نسخة بخيارات مرتبة عشوائيًا.
  QItem shuffled(math.Random r) {
    final idx = List<int>.generate(options.length, (i) => i)..shuffle(r);
    return QItem(q, [for (final i in idx) options[i]], idx.indexOf(answer), why, ref: ref, focus: focus, audio: audio);
  }
}

/// توليد تمارين تطبيقية على آيات حقيقية من المصحف.
class Drill {
  static List<QItem> make(List<String> ruleKeys, int count, {int? seed}) {
    if (!TajweedData.ready || ruleKeys.isEmpty) return [];
    final r = math.Random(seed);
    final wanted = ruleKeys.map(ruleIndex).where((i) => i >= 0).toSet();
    // آيات جزء عمّ وتبارك والفاتحة
    final pool = <AyahRef>[...QuranData.surahAyahs(1), ...QuranData.juzAyahs(30), ...QuranData.juzAyahs(29)];
    pool.shuffle(r);
    final out = <QItem>[];
    final usedRules = <int, int>{};
    for (final ref in pool) {
      if (out.length >= count) break;
      final ta = TajweedData.of(ref);
      if (ta == null) continue;
      final cands = ta.spans.where((s) => wanted.contains(s.rule)).toList();
      if (cands.isEmpty) continue;
      // توزيع متوازن بين الأحكام
      cands.sort((a, b) => (usedRules[a.rule] ?? 0).compareTo(usedRules[b.rule] ?? 0));
      final s = cands.first;
      usedRules[s.rule] = (usedRules[s.rule] ?? 0) + 1;
      final right = tRules[s.rule].name;
      final names = <String>{right};
      for (final k in wanted) {
        names.add(tRules[k].name);
      }
      final extra = ['إظهار', 'إخفاء', 'إدغام بغنة', 'إقلاب', 'قلقلة', 'مد طبيعي', 'غنة', 'مد لازم', 'لام شمسية'];
      extra.shuffle(r);
      for (final e in extra) {
        if (names.length >= 4) break;
        names.add(e);
      }
      final opts = names.take(4).toList();
      if (!opts.contains(right)) opts[0] = right;
      out.add(QItem('ما حكم التجويد في الموضع المميّز؟', opts, opts.indexOf(right), tRules[s.rule].desc,
              ref: ref, focus: (s.start, s.end))
          .shuffled(r));
    }
    return out;
  }
}
