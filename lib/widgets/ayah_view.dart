import 'package:flutter/material.dart';
import '../theme.dart';
import '../logic/matcher.dart';
import '../logic/letters.dart';

/// عرض الآية كلمةً كلمة مع تلوين الأخطاء بالأحمر والصحيح بالأخضر.
class AyahView extends StatelessWidget {
  final List<String> words;
  final int? ayah;
  final MatchResult? result;
  final double fontSize;
  /// عدد الكلمات المخفية في النهاية (للاختبار).
  final int hiddenFrom;
  /// false = بعد التقييم نُظهر الكلمات الصحيحة بس، والباقي يفضل مخفي (الغلط/الناقص شرطة حمرا)
  final bool revealAll;
  /// النتيجة من المصحِّح الذكي: الحروف الغلط بالأحمر داخل الكلمة
  final bool letters;
  const AyahView({
    super.key,
    required this.words,
    this.ayah,
    this.result,
    this.fontSize = 26,
    this.hiddenFrom = -1,
    this.revealAll = true,
    this.letters = false,
  });

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      var color = C.text;
      TextDecoration? deco;
      final r = result;
      if (r != null && i < r.words.length) {
        switch (r.words[i].state) {
          case WordState.correct:
            color = C.green;
            break;
          case WordState.wrong:
          case WordState.missing:
            color = C.red;
            deco = TextDecoration.underline;
            break;
          case WordState.given:
            color = C.muted;
            break;
          default:
            break;
        }
      }
      final ok = r != null && i < r.words.length && r.words[i].state == WordState.correct;
      final hidden = hiddenFrom >= 0 && i >= hiddenFrom && (r == null || (!revealAll && !ok));
      final missed = hidden && r != null;
      if (!hidden && letters && r != null && i < r.words.length && r.words[i].state == WordState.wrong && r.words[i].heard != null) {
        final bad = Letters.badPositions(words[i], r.words[i].heard!);
        if (bad.isNotEmpty) {
          final w = words[i];
          final badChars = <int>{};
          for (final k in bad) {
            badChars.add(k);
            var q = k + 1;
            while (q < w.length && Letters.base(w[q]) == null) {
              badChars.add(q);
              q++;
            }
          }
          var k = 0;
          while (k < w.length) {
            final b = badChars.contains(k);
            var e = k + 1;
            while (e < w.length && badChars.contains(e) == b) {
              e++;
            }
            spans.add(TextSpan(
              text: w.substring(k, e),
              style: TextStyle(
                color: b ? C.red : C.text.withOpacity(0.85),
                backgroundColor: b ? C.red.withOpacity(0.14) : null,
                decoration: TextDecoration.underline,
                decorationColor: C.red,
                decorationStyle: TextDecorationStyle.wavy,
              ),
            ));
            k = e;
          }
          spans.add(TextSpan(text: ' '));
          continue;
        }
      }
      spans.add(TextSpan(
        text: hidden ? '${'ـ' * (words[i].length.clamp(2, 6).toInt())} ' : '${words[i]} ',
        style: TextStyle(
          color: missed ? C.red : (hidden ? C.line2 : color),
          decoration: deco,
          decorationColor: C.red,
          decorationStyle: TextDecorationStyle.wavy,
        ),
      ));
    }
    if (ayah != null) {
      spans.add(TextSpan(text: '۝${ar(ayah!)}', style: TextStyle(color: C.gold)));
    }
    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(style: quranStyle.copyWith(fontSize: fontSize), children: spans),
    );
  }
}
