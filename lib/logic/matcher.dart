import 'dart:math' as math;

enum WordState { pending, correct, wrong, missing, given }

class WordResult {
  final WordState state;
  final String? heard;
  const WordResult(this.state, [this.heard]);
}

class MatchResult {
  final List<WordResult> words;
  final List<String> extra;
  MatchResult(this.words, this.extra);

  Iterable<WordResult> get _scored => words.where((w) => w.state != WordState.given);
  int get total => _scored.length;
  int get correct => _scored.where((w) => w.state == WordState.correct).length;
  int get errors => total - correct;
  double get score => total == 0 ? 1 : correct / total;
  bool get perfect => errors == 0;
}

/// مقارنة ما قرأه المستخدم بنص الآية كلمةً كلمة.
class Matcher {
  static final _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]');
  static final _nonLetters = RegExp('[^ء-ي]');

  static String normalize(String w) {
    var s = w.replaceAll(_marks, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    s = s.replaceAll(_nonLetters, '');
    return s;
  }

  static int _lev(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
      }
      prev = cur;
    }
    return prev[b.length];
  }

  static bool similar(String a, String b) {
    if (a == b) return true;
    if (a.isEmpty || b.isEmpty) return false;
    // «ال» قد تُسقط في التعرف على الصوت عند الوصل
    final a2 = a.startsWith('ال') ? a.substring(2) : a;
    final b2 = b.startsWith('ال') ? b.substring(2) : b;
    if (a2 == b2 && a2.length >= 2) return true;
    final maxLen = math.max(a.length, b.length);
    if (maxLen <= 3) return _lev(a, b) == 0 || (maxLen == 3 && _lev(a, b) <= 1 && a[0] == b[0]);
    final sim = 1 - _lev(a, b) / maxLen;
    return sim >= 0.7;
  }

  /// [expected]: كلمات الآية. [givenCount]: عدد الكلمات الأولى المعطاة (لا تُحتسب).
  static MatchResult match(List<String> expected, String heardText, {int givenCount = 0}) {
    final e = expected.map(normalize).toList();
    final h = heardText.split(RegExp(r'\s+')).map(normalize).where((w) => w.isNotEmpty).toList();
    final n = e.length, m = h.length;
    // dp[i][j] = أقل تكلفة لمحاذاة أول i كلمة متوقعة مع أول j كلمة مسموعة
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    for (var i = 0; i <= n; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j <= m; j++) {
      dp[0][j] = j;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final sub = dp[i - 1][j - 1] + (similar(e[i - 1], h[j - 1]) ? 0 : 1);
        final del = dp[i - 1][j] + 1;
        final ins = dp[i][j - 1] + 1;
        dp[i][j] = math.min(sub, math.min(del, ins));
      }
    }
    final res = List<WordResult>.filled(n, const WordResult(WordState.missing));
    final extra = <String>[];
    var i = n, j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final ok = similar(e[i - 1], h[j - 1]);
        if (dp[i][j] == dp[i - 1][j - 1] + (ok ? 0 : 1)) {
          res[i - 1] = ok ? const WordResult(WordState.correct) : WordResult(WordState.wrong, h[j - 1]);
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        res[i - 1] = const WordResult(WordState.missing);
        i--;
      } else {
        extra.add(h[j - 1]);
        j--;
      }
    }
    for (var k = 0; k < givenCount && k < n; k++) {
      res[k] = const WordResult(WordState.given);
    }
    return MatchResult(res, extra.reversed.toList());
  }

  /// ملاحظة تصحيح مبسطة لكل خطأ.
  static String note(String word, WordResult r) {
    switch (r.state) {
      case WordState.missing:
        return 'لم أسمع هذه الكلمة. اقرأها بوضوح ولا تتجاوزها.';
      case WordState.wrong:
        return 'سمعتُ «${r.heard}» بدل «$word». استمع للشيخ جيدًا ثم كرّر الكلمة ٣ مرات.';
      default:
        return '';
    }
  }
}
