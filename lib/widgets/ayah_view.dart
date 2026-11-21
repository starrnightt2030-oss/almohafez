import 'package:flutter/material.dart';
import '../theme.dart';
import '../logic/matcher.dart';

/// عرض الآية كلمةً كلمة مع تلوين الأخطاء بالأحمر والصحيح بالأخضر.
class AyahView extends StatelessWidget {
  final List<String> words;
  final int? ayah;
  final MatchResult? result;
  final double fontSize;
  /// عدد الكلمات المخفية في النهاية (للاختبار).
  final int hiddenFrom;
  const AyahView({
    super.key,
    required this.words,
    this.ayah,
    this.result,
    this.fontSize = 26,
    this.hiddenFrom = -1,
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
      final hidden = hiddenFrom >= 0 && i >= hiddenFrom && r == null;
      spans.add(TextSpan(
        text: hidden ? '${'ـ' * (words[i].length.clamp(2, 6).toInt())} ' : '${words[i]} ',
        style: TextStyle(
          color: hidden ? C.line2 : color,
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
