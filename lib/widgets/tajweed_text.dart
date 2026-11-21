import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../logic/matcher.dart';
import '../logic/tajweed_rules.dart';
import 'ayah_view.dart';

/// لون الحكم مضبوط ليظهر واضحًا على الثيمات الفاتحة.
Color ruleColor(int r) {
  final c = tRules[r].color;
  if (C.dark) return c;
  final h = HSLColor.fromColor(c);
  return h.withLightness((h.lightness * 0.62).clamp(0.0, 1.0)).withSaturation((h.saturation * 1.05).clamp(0.0, 1.0)).toColor();
}

/// آية بألوان أحكام التجويد، مع تلوين أخطاء التلاوة، ولمس الكلمة لمعرفة حكمها.
class TajweedAyahView extends StatefulWidget {
  final AyahRef ref;
  final double fontSize;
  final MatchResult? result;
  final bool showNumber;
  final bool? colors;
  final bool tappable;
  /// تمييز موضع معيّن (للتمارين): [start, end).
  final (int, int)? focus;
  final bool dimRules;
  const TajweedAyahView({
    super.key,
    required this.ref,
    this.fontSize = 26,
    this.result,
    this.showNumber = true,
    this.colors,
    this.tappable = true,
    this.focus,
    this.dimRules = false,
  });

  @override
  State<TajweedAyahView> createState() => _TajweedAyahViewState();
}

class _TajweedAyahViewState extends State<TajweedAyahView> {
  final List<TapGestureRecognizer> _recs = [];

  @override
  void dispose() {
    for (final r in _recs) {
      r.dispose();
    }
    super.dispose();
  }

  void _showWord(TajweedAyah ta, (int, int) w) {
    final word = ta.text.substring(w.$1, w.$2);
    final rules = <int>{};
    for (final s in ta.spans) {
      if (s.start < w.$2 && s.end > w.$1) rules.add(s.rule);
    }
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).padding.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(word, textAlign: TextAlign.center, style: quranStyle.copyWith(fontSize: 36)),
          SizedBox(height: 10),
          if (rules.isEmpty)
            Text('لا يوجد حكم تجويد خاص في هذه الكلمة.', textAlign: TextAlign.center, style: TextStyle(color: C.muted))
          else
            for (final r in rules)
              Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ruleColor(r).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ruleColor(r).withOpacity(0.5)),
                ),
                child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: ruleColor(r), shape: BoxShape.circle)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tRules[r].name, style: TextStyle(color: ruleColor(r), fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text(tRules[r].desc, style: TextStyle(color: C.muted, fontSize: 12.5, height: 1.6)),
                    ]),
                  ),
                ]),
              ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recs) {
      r.dispose();
    }
    _recs.clear();
    final ta = TajweedData.of(widget.ref);
    final simple = QuranData.simpleWords(widget.ref);
    final res = widget.result;
    final words = ta?.wordRanges();
    if (ta == null || words == null || (res != null && words.length != simple.length)) {
      return AyahView(
        words: QuranData.displayWords(widget.ref),
        ayah: widget.showNumber ? widget.ref.a : null,
        result: res,
        fontSize: widget.fontSize,
      );
    }
    final useColors = widget.colors ?? Progress.tajweedColors;
    final colors = List<Color?>.filled(ta.text.length, null);
    if (useColors) {
      for (final s in ta.spans) {
        final c = widget.dimRules ? ruleColor(s.rule).withOpacity(0.35) : ruleColor(s.rule);
        for (var i = s.start; i < s.end && i < colors.length; i++) {
          colors[i] = c;
        }
      }
    }
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (var wi = 0; wi < words.length; wi++) {
      final w = words[wi];
      if (w.$1 > cursor) {
        // مسافات وعلامات وقف
        spans.add(TextSpan(text: ta.text.substring(cursor, w.$1), style: TextStyle(color: C.muted)));
      }
      WordState? st;
      if (res != null && wi < res.words.length) st = res.words[wi].state;
      final isErr = st == WordState.wrong || st == WordState.missing;
      TapGestureRecognizer? rec;
      if (widget.tappable && res == null) {
        rec = TapGestureRecognizer()..onTap = () => _showWord(ta, w);
        _recs.add(rec);
      }
      var i = w.$1;
      while (i < w.$2) {
        final c = colors[i];
        var j = i + 1;
        while (j < w.$2 && colors[j] == c) {
          j++;
        }
        final inFocus = widget.focus != null && i < widget.focus!.$2 && j > widget.focus!.$1;
        Color col = c ?? C.text;
        if (isErr) col = C.red;
        if (widget.focus != null && !inFocus) col = col.withOpacity(0.45);
        if (inFocus) col = C.goldLight;
        spans.add(TextSpan(
          text: ta.text.substring(i, j),
          recognizer: rec,
          style: TextStyle(
            color: col,
            decoration: isErr || inFocus ? TextDecoration.underline : null,
            decorationColor: isErr ? C.red : C.gold,
            decorationStyle: isErr ? TextDecorationStyle.wavy : TextDecorationStyle.solid,
            backgroundColor: inFocus ? C.gold.withOpacity(0.12) : null,
          ),
        ));
        i = j;
      }
      cursor = w.$2;
    }
    if (cursor < ta.text.length) {
      spans.add(TextSpan(text: ta.text.substring(cursor), style: TextStyle(color: C.muted)));
    }
    if (widget.showNumber) {
      spans.add(TextSpan(text: ' ۝${ar(widget.ref.a)}', style: TextStyle(color: C.gold)));
    }
    return RichText(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(style: quranStyle.copyWith(fontSize: widget.fontSize), children: spans),
    );
  }
}

/// دليل ألوان أحكام التجويد.
class TajweedLegend extends StatelessWidget {
  const TajweedLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (final k in legendRules)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: ruleColor(ruleIndex(k)), shape: BoxShape.circle)),
            SizedBox(width: 4),
            Text(tRules[ruleIndex(k)].name, style: TextStyle(fontSize: 11, color: C.muted)),
          ]),
      ],
    );
  }
}
