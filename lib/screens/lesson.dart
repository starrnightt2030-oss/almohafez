import 'dart:math' as math;
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../data/course.dart';
import '../data/progress.dart';
import '../logic/drill.dart';
import '../services/audio.dart';
import '../services/voice.dart';
import '../widgets/tajweed_text.dart';
import 'hifz_session.dart';

const passRatio = 0.8;

/// شاشة الدرس: فقرات مقروءة صوتيًا ومتزامنة مع النص، وأمثلة صوتية، ثم اختبار.
class LessonScreen extends StatefulWidget {
  final Unit unit;
  final int index;
  final bool quranExamples;
  const LessonScreen({super.key, required this.unit, required this.index, this.quranExamples = true});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int? _para;
  bool _playing = false;
  int _run = 0;
  int? _exPlaying;
  final _keys = <GlobalKey>[];

  Lesson get _l => widget.unit.lessons[widget.index];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _l.paras.length; i++) {
      _keys.add(GlobalKey());
    }
    if (!Progress.lessonPassed(_l.id)) Voice.cue('lesson_start');
  }

  @override
  void dispose() {
    _run++;
    Voice.stop();
    Sheikh.stop();
    super.dispose();
  }

  Future<void> _playFrom(int start) async {
    final run = ++_run;
    await Sheikh.stop();
    setState(() {
      _playing = true;
      _exPlaying = null;
    });
    for (var i = start; i < _l.paras.length; i++) {
      if (!mounted || run != _run) return;
      setState(() => _para = i);
      final ctx = _keys[i].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: Duration(milliseconds: 450), alignment: 0.2, curve: Curves.easeOutCubic);
      }
      if (i + 1 < _l.paras.length) Voice.prefetch('assets/audio/lessons/${_l.id}_${i + 2}');
      await Voice.narrate(_l.id, i, _l.paras[i]);
      if (!mounted || run != _run) return;
      await Future.delayed(Duration(milliseconds: 350));
    }
    if (mounted && run == _run) {
      setState(() {
        _playing = false;
        _para = null;
      });
    }
  }

  Future<void> _stop() async {
    _run++;
    await Voice.stop();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _playExample(int i, Example e) async {
    await _stop();
    if (_exPlaying == i) {
      await Sheikh.stop();
      setState(() => _exPlaying = null);
      return;
    }
    setState(() => _exPlaying = i);
    try {
      await Sheikh.play('Husary_Muallim_128kbps', e.ref!.s, e.ref!.a);
    } catch (_) {
      if (mounted) toast(context, 'تعذّر التشغيل. تأكد من الاتصال بالإنترنت.');
    }
    if (mounted && _exPlaying == i) setState(() => _exPlaying = null);
  }

  Future<void> _startQuiz() async {
    await _stop();
    await Sheikh.stop();
    if (!mounted) return;
    final items = [
      for (var k = 0; k < _l.quiz.length; k++)
        QItem(_l.quiz[k].q, _l.quiz[k].options, _l.quiz[k].answer, _l.quiz[k].why, audio: 'assets/audio/quiz/${_l.id}_${k + 1}'),
    ];
    final pct = await go<int>(context, QuizScreen(title: 'اختبار: ${_l.title}', items: items));
    if (pct == null) return;
    if (pct >= passRatio * 100) {
      final first = !Progress.lessonPassed(_l.id);
      await Progress.passLesson(_l.id, pct);
      if (first) {
        await Progress.addXp(30);
        if (widget.index < widget.unit.lessons.length - 1) Voice.cue('lesson_unlocked');
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final l = _l;
    final passed = Progress.lessonPassed(l.id);
    final human = Voice.hasRecording(l.id, 0);
    final last = widget.index == u.lessons.length - 1;
    return AppPage(
      title: u.title,
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        Row(children: [
          Text('الدرس ${ar(widget.index + 1)} من ${ar(u.lessons.length)}', style: TextStyle(color: C.muted, fontSize: 12.5)),
          Spacer(),
          if (passed) Tag('أتقنته · ${ar(Progress.lessonScore(l.id) ?? 0)}٪', fg: C.green, bg: C.greenSoft),
        ]),
        SizedBox(height: 8),
        ProgressBar(value: (widget.index + 1) / u.lessons.length),
        SizedBox(height: 16),
        Text(l.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)).enter(0),
        SizedBox(height: 14),
        Panel(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          gradient: LinearGradient(colors: [C.goldSoft, C.surface]),
          border: C.goldLine,
          child: Row(children: [
            Pressable(
              onTap: _playing ? _stop : () => _playFrom(_para ?? 0),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.gold),
                child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: C.onGold, size: 30),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_playing ? 'جارٍ شرح الفقرة ${ar((_para ?? 0) + 1)}' : 'استمع إلى شرح الدرس',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(human ? 'بصوت المعلّم' : 'قراءة صوتية · المس أي فقرة لتبدأ منها',
                    style: TextStyle(fontSize: 11.5, color: C.muted)),
              ]),
            ),
            if (_playing)
              Icon(Icons.graphic_eq_rounded, color: C.gold)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleY(begin: 0.6, end: 1.1, duration: 500.ms),
          ]),
        ).enter(1),
        SizedBox(height: 14),
        for (var i = 0; i < l.paras.length; i++)
          Padding(
            key: _keys[i],
            padding: EdgeInsets.only(bottom: 10),
            child: Pressable(
              onTap: () => _playFrom(i),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _para == i ? C.highlight : C.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _para == i ? C.gold : C.line, width: _para == i ? 1.5 : 1),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: _para == i ? C.gold : C.deep, shape: BoxShape.circle),
                    child: Text(ar(i + 1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _para == i ? C.onGold : C.muted)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(l.paras[i],
                        style: TextStyle(fontSize: 15.5, height: 1.95, color: _para == i ? C.text : C.textSoft)),
                  ),
                ]),
              ),
            ),
          ).enter(2 + i),
        if (l.examples.isNotEmpty) ...[
          SizedBox(height: 8),
          SectionTitle('أمثلة تطبيقية'),
          for (var i = 0; i < l.examples.length; i++) _example(i, l.examples[i]).enter(3 + l.paras.length + i),
        ],
        if (widget.quranExamples && l.examples.isNotEmpty) ...[
          SizedBox(height: 4),
          Center(child: TajweedLegend()),
        ],
        SizedBox(height: 18),
        GoldButton(
          label: passed ? 'أعد اختبار الدرس' : 'ابدأ اختبار الدرس',
          icon: Icons.quiz_rounded,
          onPressed: _startQuiz,
        ),
        SizedBox(height: 10),
        if (passed && !last)
          GoldButton(
            label: 'الدرس التالي',
            outlined: true,
            icon: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pushReplacement(fadeRoute(LessonScreen(unit: u, index: widget.index + 1, quranExamples: widget.quranExamples))),
          ),
        if (!passed)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('اجتز الاختبار بنسبة ٨٠٪ لتفتح الدرس التالي.', textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12.5)),
          ),
      ]),
    );
  }

  Widget _example(int i, Example e) {
    final on = _exPlaying == i;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Panel(
        color: C.deep,
        border: on ? C.green : C.line2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(e.text, textAlign: TextAlign.center, style: quranStyle.copyWith(fontSize: 28)),
          Text(e.note, textAlign: TextAlign.center, style: TextStyle(color: C.gold, fontSize: 13)),
          if (e.ref != null) ...[
            SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: GoldButton(
                  label: on ? 'إيقاف' : 'استمع للشيخ',
                  icon: on ? Icons.stop_rounded : Icons.volume_up_rounded,
                  outlined: true,
                  height: 44,
                  onPressed: () => _playExample(i, e),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: GoldButton(
                  label: 'طبّق بصوتك',
                  icon: Icons.mic_rounded,
                  height: 44,
                  onPressed: () async {
                    await _stop();
                    await Sheikh.stop();
                    if (!mounted) return;
                    go(context, HifzSession(surah: e.ref!.s, startAyah: e.ref!.a, single: true));
                  },
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

/// اختبار عام بأسئلة اختيار من متعدد، مع صوت يوجّه بعد كل إجابة.
class QuizScreen extends StatefulWidget {
  final String title;
  final List<QItem> items;
  const QuizScreen({super.key, required this.title, required this.items});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final List<QItem> _items;
  final _confetti = ConfettiController(duration: Duration(seconds: 2));
  int _i = 0;
  int? _picked;
  int _correct = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _items = widget.items.map((q) => q.shuffled(r)).toList();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Voice.cue('quiz_start');
      _read();
    });
  }

  @override
  void dispose() {
    Voice.stop();
    _confetti.dispose();
    super.dispose();
  }

  void _read() {
    if (_done || !mounted) return;
    final q = _items[_i];
    Voice.say(q.q, clip: q.audio == null ? null : '${q.audio}_q');
  }

  void _pick(int o) {
    if (_picked != null) return;
    final q = _items[_i];
    final ok = o == q.answer;
    setState(() {
      _picked = o;
      if (ok) _correct++;
    });
    if (ok) {
      HapticFeedback.lightImpact();
      Voice.cue('quiz_correct');
    } else {
      HapticFeedback.heavyImpact();
      () async {
        await Voice.cue('quiz_wrong');
        if (mounted && _picked == o) await Voice.say(q.why, clip: q.audio == null ? null : '${q.audio}_w');
      }();
    }
  }

  void _next() {
    if (_i + 1 >= _items.length) {
      final pct = (_correct * 100 / _items.length).round();
      setState(() => _done = true);
      final lvl = Progress.level;
      Progress.addXp(_correct * 5).then((_) {
        if (Progress.level > lvl) Voice.cue('level_up');
      });
      if (pct >= passRatio * 100) {
        _confetti.play();
        Voice.cue('quiz_pass');
      } else {
        Voice.cue('quiz_fail');
      }
      return;
    }
    setState(() {
      _i++;
      _picked = null;
    });
    _read();
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_correct * 100 / _items.length).round();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_done ? pct : null);
      },
      child: AppPage(
        title: widget.title,
        body: Stack(children: [
          _done ? _result(pct) : _question(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 28,
              colors: [C.gold, C.green, C.blue, C.coral, C.purple],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _question() {
    final q = _items[_i];
    return ListView(key: ValueKey(_i), padding: EdgeInsets.all(20), children: [
      Row(children: [
        Text('السؤال ${ar(_i + 1)} من ${ar(_items.length)}', style: TextStyle(color: C.muted)),
        Spacer(),
        IconButton(onPressed: () => Voice.say(q.q, clip: q.audio == null ? null : '${q.audio}_q', force: true), icon: Icon(Icons.volume_up_rounded, color: C.gold), tooltip: 'اقرأ السؤال'),
      ]),
      ProgressBar(value: (_i + 1) / _items.length),
      SizedBox(height: 18),
      Text(q.q, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.6)).enter(0),
      if (q.ref != null) ...[
        SizedBox(height: 12),
        Panel(
          color: C.deep,
          border: C.line2,
          child: TajweedAyahView(ref: q.ref!, focus: q.focus, colors: false, tappable: false, fontSize: 24),
        ).enter(1),
      ],
      SizedBox(height: 16),
      for (var o = 0; o < q.options.length; o++)
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Panel(
            onTap: () => _pick(o),
            color: _picked == null ? C.surface : (o == q.answer ? C.greenSoft : (o == _picked ? C.redSoft : C.surface)),
            border: _picked == null ? C.line : (o == q.answer ? C.green : (o == _picked ? C.red : C.line)),
            child: Row(children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: C.deep, shape: BoxShape.circle, border: Border.all(color: C.line2)),
                child: _picked != null && o == q.answer
                    ? Icon(Icons.check_rounded, size: 18, color: C.green)
                    : (_picked == o ? Icon(Icons.close_rounded, size: 18, color: C.red) : Text(ar(o + 1), style: TextStyle(fontSize: 12, color: C.muted))),
              ),
              SizedBox(width: 12),
              Expanded(child: Text(q.options[o], style: TextStyle(fontSize: 15.5))),
            ]),
          ).enter(2 + o),
        ),
      if (_picked != null) ...[
        Panel(
          color: _picked == q.answer ? C.greenSoft : C.redSoft,
          border: _picked == q.answer ? C.line2 : C.redLine,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_picked == q.answer ? Icons.lightbulb_rounded : Icons.info_rounded, color: _picked == q.answer ? C.green : C.red),
            SizedBox(width: 10),
            Expanded(child: Text(q.why, style: TextStyle(height: 1.7))),
          ]),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
        SizedBox(height: 16),
        GoldButton(label: _i + 1 >= _items.length ? 'عرض النتيجة' : 'التالي', onPressed: _next),
      ],
    ]);
  }

  Widget _result(int pct) {
    final pass = pct >= passRatio * 100;
    return ListView(padding: EdgeInsets.all(24), children: [
      SizedBox(height: 20),
      Center(child: ScoreRing(value: pct / 100, size: 150, label: '${ar(pct)}٪', sub: 'النتيجة', color: pass ? C.gold : C.red)),
      SizedBox(height: 20),
      Text(pass ? 'أتقنت هذا الجزء، بارك الله فيك!' : 'تحتاج ٨٠٪ على الأقل. راجع الشرح ثم أعد المحاولة.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 17, height: 1.7, fontWeight: FontWeight.w500)),
      SizedBox(height: 8),
      Text('أجبت ${ar(_correct)} من ${ar(_items.length)} إجابة صحيحة · +${ar(_correct * 5)} نقطة',
          textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
      SizedBox(height: 28),
      GoldButton(label: pass ? 'متابعة' : 'رجوع للمراجعة', onPressed: () => Navigator.of(context).pop(pct)),
    ]);
  }
}
