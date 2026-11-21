import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../logic/matcher.dart';
import '../services/audio.dart';
import '../services/speech.dart';
import '../services/voice.dart';
import '../widgets/ayah_view.dart';
import 'certificate.dart';

class _Q {
  final AyahRef ref;
  final List<String> words;
  final List<String> simple;
  final int given;
  final int firstLen;
  double? score;
  MatchResult? result;
  int hints = 0;
  _Q(this.ref, this.words, this.simple, this.given, this.firstLen);
}

enum _P { sheikh, user, result }

/// اختبار «كمّل الآية»: الشيخ يقرأ بداية آية، وأنت تكملها وتقرأ ما بعدها.
class TestScreen extends StatefulWidget {
  final String title;
  final List<AyahRef> pool;
  final int questions;
  final int? certSurah;
  final bool placement;
  const TestScreen._({required this.title, required this.pool, required this.questions, this.certSurah, this.placement = false});

  factory TestScreen.surah(int s) {
    final su = QuranData.surah(s);
    final n = su.count <= 3 ? 1 : (su.count < 8 ? 3 : (su.count < 30 ? 5 : 8));
    return TestScreen._(title: 'اختبار سورة ${su.name}', pool: QuranData.surahAyahs(s), questions: n, certSurah: s);
  }

  factory TestScreen.range(String title, List<AyahRef> pool, {int questions = 6}) =>
      TestScreen._(title: title, pool: pool, questions: questions);

  factory TestScreen.placement() =>
      TestScreen._(title: 'تحديد المستوى', pool: QuranData.juzAyahs(30), questions: 3, placement: true);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _rnd = math.Random();
  final List<_Q> _qs = [];
  final Set<AyahRef> _used = {};
  int _i = 0;
  _P _phase = _P.sheikh;
  String _heard = '';
  int _run = 0;
  bool _done = false;
  // تحديد المستوى
  int _juz = 30;
  int _juzPassed = 0;
  final List<double> _juzScores = [];

  @override
  void initState() {
    super.initState();
    _build(widget.pool, widget.questions);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Voice.cue('test_start');
      if (mounted) _start();
    });
  }

  @override
  void dispose() {
    _run++;
    Sheikh.stop();
    Ear.cancel();
    Voice.stop();
    super.dispose();
  }

  void _build(List<AyahRef> pool, int count) {
    final shuffled = [...pool]..shuffle(_rnd);
    var added = 0;
    for (final r in shuffled) {
      if (added >= count) break;
      if (_used.contains(r)) continue;
      final q = _make(r);
      if (q == null) continue;
      _used.add(r);
      _qs.add(q);
      added++;
    }
  }

  _Q? _make(AyahRef r) {
    final su = QuranData.surah(r.s);
    final next = r.a < su.count ? AyahRef(r.s, r.a + 1) : null;
    final dw = QuranData.displayWords(r);
    final sw = QuranData.simpleWords(r);
    final n = sw.length;
    int k;
    if (n <= 2) {
      if (next == null) return null;
      k = n;
    } else {
      k = math.min(5, (n / 3).round().clamp(1, n - 1).toInt());
    }
    final words = [...dw];
    words[words.length - 1] = '${words.last} ۝${ar(r.a)}';
    final simple = [...sw];
    if (next != null && n - k <= 25) {
      final dn = [...QuranData.displayWords(next)];
      dn[dn.length - 1] = '${dn.last} ۝${ar(next.a)}';
      words.addAll(dn);
      simple.addAll(QuranData.simpleWords(next));
    }
    return _Q(r, words, simple, k, n);
  }

  _Q get _q => _qs[_i];

  Future<void> _start() async {
    final run = ++_run;
    await Ear.cancel();
    await Voice.stop();
    setState(() {
      _phase = _P.sheikh;
      _heard = '';
    });
    final q = _q;
    final frac = q.given >= q.firstLen ? null : (q.given / q.firstLen) * 0.92;
    try {
      await Sheikh.play(Progress.reciter, q.ref.s, q.ref.a, fraction: frac);
    } catch (_) {
      if (mounted) toast(context, 'تعذّر تشغيل صوت الشيخ — اقرأ البداية من الشاشة.');
    }
    if (!mounted || run != _run) return;
    await _listen(run);
  }

  Future<void> _listen([int? runId]) async {
    final run = runId ?? ++_run;
    await Sheikh.stop();
    final ok = await Ear.init();
    if (!mounted || run != _run) return;
    if (!ok) {
      toast(context, 'اسمح للتطبيق باستخدام الميكروفون لإجراء الاختبار.');
      return;
    }
    setState(() {
      _phase = _P.user;
      _heard = '';
    });
    try {
      await Ear.listen(
        onText: (t) {
          if (mounted && run == _run) setState(() => _heard = t);
        },
        onDone: (t) {
          if (mounted && run == _run) _evaluate(t);
        },
      );
    } catch (_) {}
  }

  void _evaluate(String heard) {
    final q = _q;
    final res = Matcher.match(q.simple, heard, givenCount: q.given + q.hints);
    Progress.touchToday();
    setState(() {
      _heard = heard;
      q.result = res;
      q.score = heard.trim().isEmpty ? 0 : res.score;
      _phase = _P.result;
    });
    final sc = q.score ?? 0;
    if (heard.trim().isEmpty) {
      Voice.cue('no_voice');
    } else if (sc >= 0.8) {
      Voice.cue('test_good');
    } else {
      Voice.cue('test_bad');
    }
  }

  void _skip() {
    _run++;
    Sheikh.stop();
    Ear.cancel();
    setState(() {
      _q.score = 0;
      _q.result = Matcher.match(_q.simple, '', givenCount: _q.given + _q.hints);
      _phase = _P.result;
    });
  }

  void _hint() {
    final q = _q;
    if (q.given + q.hints < q.words.length - 1) {
      setState(() => q.hints++);
      Voice.cue('hint');
    }
  }

  void _nextQ() {
    if (widget.placement) {
      _juzScores.add(_q.score ?? 0);
      if (_juzScores.length >= 3) {
        final avg = _juzScores.reduce((a, b) => a + b) / _juzScores.length;
        _juzScores.clear();
        if (avg >= 0.6) {
          _juzPassed++;
          if (_juz > 1) {
            _juz--;
            _build(QuranData.juzAyahs(_juz), 3);
          }
        }
        if (avg < 0.6 || _i + 1 >= _qs.length) {
          Progress.setPlacement(_juzPassed);
          setState(() => _done = true);
          return;
        }
      }
    }
    if (_i + 1 >= _qs.length) {
      setState(() => _done = true);
      if (widget.certSurah != null) Progress.setTest(widget.certSurah!, (_avg * 100).round());
      return;
    }
    setState(() => _i++);
    _start();
  }

  double get _avg {
    final s = _qs.where((q) => q.score != null).map((q) => q.score!).toList();
    if (s.isEmpty) return 0;
    return s.reduce((a, b) => a + b) / s.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_qs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(child: Text('لا توجد أسئلة متاحة لهذا النطاق.', style: TextStyle(color: C.muted))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(widget.title),
          if (!_done)
            Text(
              widget.placement ? 'الجزء ${ar(_juz)} · السؤال ${ar(_i + 1)}' : 'السؤال ${ar(_i + 1)} من ${ar(_qs.length)}',
              style: TextStyle(fontSize: 12, color: C.muted),
            ),
        ]),
      ),
      body: SafeArea(child: _done ? _summary() : _question()),
    );
  }

  Widget _question() {
    final q = _q;
    final shown = q.given + q.hints;
    final listening = _phase == _P.user;
    return Column(children: [
      if (!widget.placement)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            for (var k = 0; k < _qs.length; k++)
              Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: k < _i
                        ? ((_qs[k].score ?? 0) >= 0.8 ? C.green : C.red)
                        : (k == _i ? C.gold : C.line),
                  ),
                ),
              ),
          ]),
        ),
      Expanded(
        child: ListView(padding: EdgeInsets.all(20), children: [
          Row(children: [
            IconBox(icon: Icons.volume_up_outlined, color: C.green, bg: C.greenSoft, size: 36),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _phase == _P.sheikh
                    ? 'الشيخ يقرأ بداية الآية…'
                    : (listening ? 'أكمل الآية واقرأ التي بعدها' : 'النتيجة'),
                style: TextStyle(color: C.muted, fontSize: 13.5),
              ),
            ),
            Text('سورة ${QuranData.surah(q.ref.s).name}', style: TextStyle(color: C.muted, fontSize: 12)),
          ]),
          SizedBox(height: 14),
          Panel(
            border: C.line2,
            radius: 24,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: AyahView(words: q.words, result: _phase == _P.result ? q.result : null, hiddenFrom: shown, fontSize: 25),
          ),
          SizedBox(height: 14),
          if (_phase == _P.result) _resultCard(q) else _tipCard(),
          if (listening && _heard.isNotEmpty) ...[
            SizedBox(height: 12),
            Text('أسمع: $_heard', textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.7)),
          ],
          if (_phase != _P.result) ...[
            SizedBox(height: 12),
            Row(children: [
              Expanded(child: GoldButton(label: 'تلميح (كلمة)', outlined: true, height: 46, onPressed: _hint)),
              SizedBox(width: 10),
              Expanded(child: GoldButton(label: 'تخطي السؤال', outlined: true, height: 46, onPressed: _skip)),
            ]),
          ],
        ]),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: _phase == _P.result
            ? Row(children: [
                Expanded(child: GoldButton(label: 'أعد المحاولة', outlined: true, onPressed: _start)),
                SizedBox(width: 10),
                Expanded(flex: 2, child: GoldButton(label: _i + 1 >= _qs.length && !widget.placement ? 'عرض النتيجة' : 'السؤال التالي', onPressed: _nextQ)),
              ])
            : Column(children: [
                GestureDetector(
                  onTap: () => listening ? Ear.stop() : _listen(),
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: listening ? C.green : C.gold,
                      boxShadow: [BoxShadow(color: C.gold.withOpacity(0.25), blurRadius: 18, spreadRadius: 4)],
                    ),
                    child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded, size: 34, color: C.bg),
                  ),
                ),
                SizedBox(height: 8),
                Text(listening ? 'اضغط عند الانتهاء' : 'اضغط وابدأ القراءة من حفظك',
                    style: TextStyle(color: C.muted, fontSize: 12.5)),
              ]),
      ),
    ]);
  }

  Widget _tipCard() => Container(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: C.goldSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.goldLine)),
        child: Row(children: [
          Icon(Icons.info_outline, color: C.gold, size: 20),
          SizedBox(width: 10),
          Expanded(
              child: Text('أكمل الآية من حيث توقّف الشيخ، ثم اقرأ الآية التي بعدها.',
                  style: TextStyle(fontSize: 13, height: 1.6, color: C.text))),
        ]),
      );

  Widget _resultCard(_Q q) {
    final pct = ((q.score ?? 0) * 100).round();
    final good = pct >= 80;
    return Panel(
      color: good ? C.greenSoft : C.redSoft,
      border: good ? C.line2 : C.redLine,
      child: Row(children: [
        Icon(good ? Icons.check_circle_outline : Icons.error_outline, color: good ? C.green : C.red),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            good
                ? 'أحسنت! أتقنت ${ar(pct)}٪ من الكلمات.'
                : 'أتقنت ${ar(pct)}٪. الكلمات الحمراء تحتاج مراجعة — راجعها مع الشيخ في جلسة الحفظ.',
            style: TextStyle(height: 1.6, fontSize: 13.5),
          ),
        ),
      ]),
    );
  }

  Widget _summary() {
    if (widget.placement) {
      return ListView(padding: EdgeInsets.all(20), children: [
        SizedBox(height: 20),
        Icon(Icons.insights_outlined, color: C.gold, size: 64),
        SizedBox(height: 16),
        Text(
          _juzPassed == 0 ? 'لنبدأ معًا من جزء عمّ' : 'تحفظ تقريبًا ${ar(_juzPassed)} جزءًا من آخر المصحف',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.5),
        ),
        SizedBox(height: 10),
        Text(
          _juzPassed >= 30
              ? 'ما شاء الله! حفظك قوي في كل الأجزاء التي اختُبرت.'
              : 'ننصحك ببدء الحفظ والمراجعة من الجزء ${ar(30 - _juzPassed)}.',
          textAlign: TextAlign.center,
          style: TextStyle(color: C.muted, height: 1.7),
        ),
        SizedBox(height: 30),
        GoldButton(label: 'رجوع', onPressed: () => Navigator.pop(context)),
      ]);
    }
    final pct = (_avg * 100).round();
    final canCert = widget.certSurah != null && pct >= 85;
    return ListView(padding: EdgeInsets.all(20), children: [
      Panel(
        radius: 24,
        child: Row(children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: _avg,
                  strokeWidth: 10,
                  backgroundColor: C.bg,
                  valueColor: AlwaysStoppedAnimation(pct >= 85 ? C.gold : C.red),
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(ar(pct), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: C.gold)),
                Text('من ١٠٠', style: TextStyle(fontSize: 11, color: C.muted)),
              ]),
            ]),
          ),
          SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(gradeOf(pct), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text(
                canCert
                    ? 'بارك الله فيك! أنت مستحق لشهادة إتمام الحفظ.'
                    : (widget.certSurah != null ? 'تحتاج ٨٥٪ على الأقل للشهادة. راجع ثم أعد الاختبار.' : 'راجع الآيات التي أخطأت فيها.'),
                style: TextStyle(color: C.muted, height: 1.6, fontSize: 13),
              ),
            ]),
          ),
        ]),
      ),
      SizedBox(height: 16),
      Text('تفاصيل الأسئلة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      SizedBox(height: 8),
      for (final q in _qs)
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Panel(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Text('سورة ${QuranData.surah(q.ref.s).name} · الآية ${ar(q.ref.a)}', style: TextStyle(fontSize: 13.5)),
              ),
              Text('${ar(((q.score ?? 0) * 100).round())}٪',
                  style: TextStyle(color: (q.score ?? 0) >= 0.8 ? C.green : C.red, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      SizedBox(height: 16),
      if (canCert)
        GoldButton(
          label: 'استلم شهادتك',
          icon: Icons.workspace_premium_outlined,
          onPressed: () => issueSurahCertificate(context, widget.certSurah!, pct),
        ),
      SizedBox(height: 10),
      GoldButton(
        label: 'أعد الاختبار',
        outlined: true,
        onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => widget.certSurah != null
              ? TestScreen.surah(widget.certSurah!)
              : TestScreen.range(widget.title, widget.pool, questions: widget.questions),
        )),
      ),
    ]);
  }
}
