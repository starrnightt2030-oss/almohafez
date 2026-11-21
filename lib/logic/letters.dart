import 'dart:math' as math;
import 'matcher.dart';

/// مقارنة التلاوة بالحروف (لنموذج التعرف على التلاوة اللي بيطلع حروف الرسم بدون تشكيل).
///
/// النموذج بيكتب ٢٩ حرف بس: ء ا ب ت ث ج ح خ د ذ ر ز س ش ص ض ط ظ ع غ ف ق ك ل م ن ه و ي
/// (أ إ آ ٱ ← ا، ة ← ه، ى ← ي) وبالرسم العثماني غالبًا (العلمين، السموت، صرط).
/// فبنقارن كل كلمة بأكتر من صورة: الرسم العثماني والإملائي، ولو اختلفوا في الألف أو الهمزة بس
/// مانعتبرهاش غلطة؛ أي حرف تاني مختلف = غلطة وبنعلّم الحرف نفسه بالأحمر.
class Letters {
  static const _letters = 'ءابتثجحخدذرزسشصضطظعغفقكلمنهوي';
  static const _map = {'أ': 'ا', 'إ': 'ا', 'آ': 'ا', 'ٱ': 'ا', 'ة': 'ه', 'ى': 'ي', 'ؤ': 'و', 'ئ': 'ي'};

  /// الحرف الأساسي بعد التوحيد، أو null لو العلامة مش حرف (تشكيل/وقف/حروف صغيرة).
  static String? base(String ch) {
    final c = _map[ch] ?? ch;
    return _letters.contains(c) ? c : null;
  }

  /// حروف الكلمة بدون تشكيل وبعد التوحيد.
  static String fold(String w) {
    final b = StringBuffer();
    for (final r in w.runes) {
      final c = base(String.fromCharCode(r));
      if (c != null) b.write(c);
    }
    return b.toString();
  }

  /// الهيكل: من غير ألف ولا همزة ومن غير تكرار متتالي — للتسامح مع فروق الرسم بين المصاحف.
  static String skeleton(String folded) {
    final b = StringBuffer();
    String? prev;
    for (final r in folded.runes) {
      final c = String.fromCharCode(r);
      if (c == 'ا' || c == 'ء') continue;
      if (c == prev) continue;
      b.write(c);
      prev = c;
    }
    return b.toString();
  }

  static int lev(String a, String b) {
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

  /// يصلح كلمات الرسم العثماني اللي اتفصلت بمسافة بعد تنوين (زي «عَمَلࣰ اۚ» و«هُدࣰ ى»).
  static List<String> repairUthmani(String text) {
    final out = <String>[];
    const tanween = 'ࣰًࣱٌࣲٍ';
    for (final t in text.split(' ')) {
      if (t.isEmpty) continue;
      final f = fold(t);
      final joinable = out.isNotEmpty &&
          (f.isEmpty || ((f == 'ا' || f == 'ي') && tanween.contains(out.last.substring(out.last.length - 1))));
      if (joinable) {
        out[out.length - 1] = out.last + t;
      } else {
        out.add(t);
      }
    }
    return out;
  }

  /// صور مقبولة لكل كلمة من كلمات الآية (بالترتيب الإملائي اللي بتتعرض بيه النتيجة).
  static List<Set<String>> forms(List<String> simple, String uthmani) {
    final u = repairUthmani(uthmani);
    final out = <Set<String>>[];
    for (var i = 0; i < simple.length; i++) {
      final s = <String>{fold(simple[i])};
      if (u.length == simple.length) s.add(fold(u[i]));
      s.removeWhere((x) => x.isEmpty);
      if (s.isEmpty) s.add('-');
      out.add(s);
    }
    return out;
  }

  /// هل الكلمة المسموعة [h] (مطوّعة) مقبولة لصور الكلمة [f]؟
  static bool accepts(Set<String> f, String h, {bool strict = false}) {
    if (h.isEmpty) return false;
    if (f.contains(h)) return true;
    final hs = skeleton(h);
    for (final x in f) {
      final xs = skeleton(x);
      if (xs == hs && xs.isNotEmpty) return true;
      // تسامح بسيط مع خطأ التعرّف في الكلمات الطويلة جدًا، بشرط إن آخر حرفين (الإعراب) سليمين
      if (!strict && xs.length >= 7 && hs.length >= 7 && lev(xs, hs) <= 1 &&
          xs.substring(xs.length - 2) == hs.substring(hs.length - 2)) return true;
    }
    return false;
  }

  /// محاذاة ما سُمع بكلمات الآية. [live] = أثناء القراءة: الكلمات اللي لسه ماوصلهاش تفضل «منتظرة» مش «ناقصة».
  static MatchResult match(List<String> simple, String uthmani, String heard, {bool strict = false, bool live = false}) {
    final f = forms(simple, uthmani);
    final h = heard.split(RegExp(r'\s+')).map(fold).where((w) => w.isNotEmpty).toList();
    final n = f.length, m = h.length;
    const inf = 1 << 30;
    // dp[i][j] = أقل تكلفة لمحاذاة أول i كلمة من الآية مع أول j كلمة مسموعة
    final dp = List.generate(n + 1, (_) => List<int>.filled(m + 1, inf));
    final from = List.generate(n + 1, (_) => List<int>.filled(m + 1, 0));
    dp[0][0] = 0;
    // في وضع المتابعة الحية الكلمات الأخيرة اللي لسه ماتقرتش مالهاش تكلفة
    bool ok(int i, int j) => accepts(f[i], h[j], strict: strict);
    String sk(Set<String> s) => skeleton(s.first);
    for (var i = 0; i <= n; i++) {
      for (var j = 0; j <= m; j++) {
        final cur = dp[i][j];
        if (cur >= inf) continue;
        void relax(int ni, int nj, int c, int kind) {
          if (ni > n || nj > m) return;
          if (cur + c < dp[ni][nj]) {
            dp[ni][nj] = cur + c;
            from[ni][nj] = kind;
          }
        }
        if (i < n && j < m) relax(i + 1, j + 1, ok(i, j) ? 0 : 2, 1); // مطابقة أو استبدال
        if (i < n) relax(i + 1, j, 2, 2); // كلمة ناقصة
        if (j < m) relax(i, j + 1, 1, 3); // كلمة زيادة
        // «يا أيها» ← «يايها»: كلمتين في الإملائي = كلمة في المسموع
        if (i + 1 < n && j < m) {
          final joined = skeleton(f[i].first + f[i + 1].first);
          if (joined.isNotEmpty && joined == skeleton(h[j])) relax(i + 2, j + 1, 0, 4);
        }
        // كلمة واحدة اتسمعت كلمتين
        if (i < n && j + 1 < m) {
          if (sk(f[i]).isNotEmpty && sk(f[i]) == skeleton(h[j] + h[j + 1])) relax(i + 1, j + 2, 0, 5);
        }
      }
    }
    // في المتابعة الحية: ناخد أحسن نقطة وصلها القارئ (مش لازم يكون خلّص الآية)
    var endI = n;
    if (live) {
      var best = inf;
      for (var i = 0; i <= n; i++) {
        final c = dp[i][m];
        if (c < best || (c == best && i > endI)) {
          best = c;
          endI = i;
        }
      }
      if (m == 0) endI = 0;
    }
    final res = List<WordResult>.filled(n, WordResult(live ? WordState.pending : WordState.missing));
    final extra = <String>[];
    var i = endI, j = m;
    while (i > 0 || j > 0) {
      final k = from[i][j];
      if (k == 1) {
        final good = ok(i - 1, j - 1);
        res[i - 1] = good ? WordResult(WordState.correct, h[j - 1]) : WordResult(WordState.wrong, h[j - 1]);
        i--;
        j--;
      } else if (k == 2) {
        res[i - 1] = WordResult(WordState.missing);
        i--;
      } else if (k == 3) {
        extra.add(h[j - 1]);
        j--;
      } else if (k == 4) {
        res[i - 1] = WordResult(WordState.correct, h[j - 1]);
        res[i - 2] = WordResult(WordState.correct, h[j - 1]);
        i -= 2;
        j--;
      } else if (k == 5) {
        res[i - 1] = WordResult(WordState.correct, '${h[j - 2]} ${h[j - 1]}');
        i--;
        j -= 2;
      } else {
        break; // مايحصلش
      }
    }
    return MatchResult(res, extra.reversed.toList());
  }

  /// هل القارئ وصل لآخر كلمة في الآية؟ (عشان ننهي الاستماع فورًا من غير انتظار)
  static bool reachedEnd(MatchResult live) {
    if (live.words.isEmpty) return true;
    return live.words.last.state == WordState.correct;
  }

  /// مواضع الحروف الغلط داخل الكلمة المعروضة [display] (بالتشكيل) مقارنةً بما سُمع [heard].
  /// بيرجع فهارس الحروف الأساسية في النص المعروض؛ اختلاف الألف/الهمزة مايتعلّمش.
  static Set<int> badPositions(String display, String heard) {
    final pos = <int>[];
    final exp = StringBuffer();
    final units = display.codeUnits;
    for (var k = 0; k < units.length; k++) {
      final c = base(String.fromCharCode(units[k]));
      if (c != null) {
        pos.add(k);
        exp.write(c);
      }
    }
    final e = exp.toString();
    final h = fold(heard.replaceAll(' ', ''));
    final n = e.length, m = h.length;
    if (n == 0) return {};
    double cIns(String ch) => (ch == 'ا' || ch == 'ء') ? 0.2 : 1;
    final dp = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      dp[i][0] = dp[i - 1][0] + cIns(e[i - 1]);
    }
    for (var j = 1; j <= m; j++) {
      dp[0][j] = dp[0][j - 1] + cIns(h[j - 1]);
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final sub = dp[i - 1][j - 1] + (e[i - 1] == h[j - 1] ? 0 : 1);
        final del = dp[i - 1][j] + cIns(e[i - 1]);
        final ins = dp[i][j - 1] + cIns(h[j - 1]);
        dp[i][j] = math.min(sub, math.min(del, ins));
      }
    }
    final bad = <int>{};
    var i = n, j = m;
    while (i > 0 && j > 0) {
      final same = e[i - 1] == h[j - 1];
      if ((dp[i][j] - (dp[i - 1][j - 1] + (same ? 0 : 1))).abs() < 1e-9) {
        if (!same) bad.add(pos[i - 1]);
        i--;
        j--;
      } else if ((dp[i][j] - (dp[i - 1][j] + cIns(e[i - 1]))).abs() < 1e-9) {
        if (e[i - 1] != 'ا' && e[i - 1] != 'ء') bad.add(pos[i - 1]);
        i--;
      } else {
        j--;
      }
    }
    while (i > 0) {
      if (e[i - 1] != 'ا' && e[i - 1] != 'ء') bad.add(pos[i - 1]);
      i--;
    }
    return bad;
  }
}
