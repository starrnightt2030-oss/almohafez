import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../data/tajweed_content.dart';
import '../services/audio.dart';
import 'certificate.dart';
import 'hifz_session.dart';

bool _unlocked(int i) => i == 0 || Progress.tajweed.containsKey('$i');
bool _passed(int i) => Progress.tajweed.containsKey('${i + 1}');

class TajweedScreen extends StatefulWidget {
  const TajweedScreen({super.key});

  @override
  State<TajweedScreen> createState() => _TajweedScreenState();
}

class _TajweedScreenState extends State<TajweedScreen> {
  @override
  Widget build(BuildContext context) {
    final lessons = tajweedLevels.fold<int>(0, (a, l) => a + l.lessons.length);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      const Text('أكاديمية التجويد', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text('برواية حفص عن عاصم · ${ar(tajweedLevels.length)} مستويات · ${ar(lessons)} درسًا',
          style: const TextStyle(fontSize: 13, color: C.muted)),
      const SizedBox(height: 16),
      for (var i = 0; i < tajweedLevels.length; i++) _level(i),
    ]);
  }

  Widget _level(int i) {
    final l = tajweedLevels[i];
    final open = _unlocked(i);
    final done = _passed(i);
    final current = open && !done;
    final badgeBg = done ? C.greenSoft : (current ? C.gold : C.deep);
    final badgeFg = done ? C.green : (current ? C.onGold : C.muted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: done ? C.green : (current ? C.gold : C.line), width: 2),
          ),
          child: done
              ? const Icon(Icons.check, color: C.green)
              : Text(ar(i + 1), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: badgeFg)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            color: current ? const Color(0xFF16291F) : (open ? C.surface : C.deep),
            border: current ? const Color(0xFF5C4B22) : C.line,
            onTap: open
                ? () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LevelScreen(index: i)));
                    if (mounted) setState(() {});
                  }
                : () => toast(context, 'اجتز اختبار المستوى السابق أولًا'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(l.title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: open ? C.text : C.muted)),
                ),
                Tag(
                  done ? 'تم · ${ar(Progress.tajweed['${i + 1}'] ?? 0)}٪' : (current ? 'جارٍ' : 'مقفل'),
                  fg: done ? C.green : (current ? const Color(0xFFF3D58F) : C.muted),
                  bg: done ? C.greenSoft : (current ? C.goldSoft : C.surface2),
                ),
              ]),
              const SizedBox(height: 4),
              Text('${l.sub} · ${ar(l.lessons.length)} دروس + اختبار',
                  style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class LevelScreen extends StatelessWidget {
  final int index;
  const LevelScreen({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final l = tajweedLevels[index];
    return Scaffold(
      appBar: AppBar(title: Text('المستوى ${ar(index + 1)}: ${l.title}')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        for (var k = 0; k < l.lessons.length; k++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Panel(
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LessonScreen(level: index, lesson: k))),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(11)),
                  child: Text(ar(k + 1), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l.lessons[k].title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
                const Icon(Icons.chevron_left, color: C.muted),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        GoldButton(
          label: 'اختبار المستوى',
          icon: Icons.quiz_outlined,
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuizScreen(level: index))),
        ),
      ]),
    );
  }
}

class LessonScreen extends StatefulWidget {
  final int level;
  final int lesson;
  const LessonScreen({super.key, required this.level, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int? _playing;

  @override
  void dispose() {
    Sheikh.stop();
    super.dispose();
  }

  Future<void> _play(int i, TExample e) async {
    if (_playing == i) {
      await Sheikh.stop();
      setState(() => _playing = null);
      return;
    }
    setState(() => _playing = i);
    try {
      await Sheikh.play('Husary_Muallim_128kbps', e.ref!.s, e.ref!.a);
    } catch (_) {
      if (mounted) toast(context, 'تعذّر التشغيل. تأكد من الاتصال بالإنترنت.');
    }
    if (mounted && _playing == i) setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final l = tajweedLevels[widget.level];
    final ls = l.lessons[widget.lesson];
    final last = widget.lesson == l.lessons.length - 1;
    return Scaffold(
      appBar: AppBar(title: Text(l.title)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('الدرس ${ar(widget.lesson + 1)} من ${ar(l.lessons.length)}', style: const TextStyle(color: C.muted, fontSize: 12.5)),
          const SizedBox(height: 6),
          ProgressBar(value: (widget.lesson + 1) / l.lessons.length),
          const SizedBox(height: 16),
          Text(ls.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Panel(child: Text(ls.body, style: const TextStyle(fontSize: 15, height: 1.95, color: Color(0xFFD6E1DC)))),
          if (ls.examples.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('أمثلة من القرآن', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (var i = 0; i < ls.examples.length; i++) _example(i, ls.examples[i]),
          ],
          const SizedBox(height: 18),
          GoldButton(
            label: last ? 'إلى اختبار المستوى' : 'الدرس التالي',
            onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (_) => last ? QuizScreen(level: widget.level) : LessonScreen(level: widget.level, lesson: widget.lesson + 1),
            )),
          ),
        ]),
      ),
    );
  }

  Widget _example(int i, TExample e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
        color: C.deep,
        border: C.line2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(e.text, textAlign: TextAlign.center, style: quranStyle.copyWith(fontSize: 26)),
          Text(e.note, textAlign: TextAlign.center, style: const TextStyle(color: C.gold, fontSize: 13)),
          if (e.ref != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: GoldButton(
                  label: _playing == i ? 'إيقاف' : 'استمع للشيخ',
                  icon: _playing == i ? Icons.stop_rounded : Icons.volume_up_outlined,
                  outlined: true,
                  height: 44,
                  onPressed: () => _play(i, e),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GoldButton(
                  label: 'طبّق بصوتك',
                  icon: Icons.mic_none_rounded,
                  height: 44,
                  onPressed: () {
                    Sheikh.stop();
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => HifzSession(surah: e.ref!.s, startAyah: e.ref!.a)));
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

class QuizScreen extends StatefulWidget {
  final int level;
  const QuizScreen({super.key, required this.level});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _i = 0;
  int? _picked;
  int _correct = 0;
  bool _done = false;

  TLevel get _l => tajweedLevels[widget.level];

  void _pick(int o) {
    if (_picked != null) return;
    setState(() {
      _picked = o;
      if (o == _l.quiz[_i].answer) _correct++;
    });
  }

  void _next() {
    if (_i + 1 >= _l.quiz.length) {
      final pct = (_correct * 100 / _l.quiz.length).round();
      if (pct >= 80) Progress.setTajweed(widget.level + 1, pct);
      setState(() => _done = true);
      return;
    }
    setState(() {
      _i++;
      _picked = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('اختبار: ${_l.title}')),
      body: SafeArea(child: _done ? _result() : _question()),
    );
  }

  Widget _question() {
    final q = _l.quiz[_i];
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('السؤال ${ar(_i + 1)} من ${ar(_l.quiz.length)}', style: const TextStyle(color: C.muted)),
      const SizedBox(height: 8),
      ProgressBar(value: (_i + 1) / _l.quiz.length),
      const SizedBox(height: 20),
      Text(q.q, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.6)),
      const SizedBox(height: 16),
      for (var o = 0; o < q.options.length; o++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Panel(
            onTap: () => _pick(o),
            color: _picked == null
                ? C.surface
                : (o == q.answer ? C.greenSoft : (o == _picked ? C.redSoft : C.surface)),
            border: _picked == null
                ? C.line
                : (o == q.answer ? C.green : (o == _picked ? C.red : C.line)),
            child: Text(q.options[o], style: const TextStyle(fontSize: 15.5)),
          ),
        ),
      if (_picked != null) ...[
        const SizedBox(height: 6),
        Text(q.why, style: const TextStyle(color: C.muted, height: 1.7)),
        const SizedBox(height: 16),
        GoldButton(label: _i + 1 >= _l.quiz.length ? 'النتيجة' : 'التالي', onPressed: _next),
      ],
    ]);
  }

  Widget _result() {
    final pct = (_correct * 100 / _l.quiz.length).round();
    final pass = pct >= 80;
    return ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 20),
      Icon(pass ? Icons.emoji_events_outlined : Icons.refresh, size: 72, color: pass ? C.gold : C.muted),
      const SizedBox(height: 14),
      Text('${ar(pct)}٪', textAlign: TextAlign.center, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: C.gold)),
      const SizedBox(height: 6),
      Text(pass ? 'نجحت في المستوى، بارك الله فيك!' : 'تحتاج ٨٠٪ للنجاح. راجع الدروس وحاول مرة أخرى.',
          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.7)),
      const SizedBox(height: 28),
      if (pass)
        GoldButton(
          label: 'استلم شهادة المستوى',
          icon: Icons.workspace_premium_outlined,
          onPressed: () => issueTajweedCertificate(context, 'المستوى ${ar(widget.level + 1)}: ${_l.title}', pct),
        ),
      const SizedBox(height: 10),
      GoldButton(
        label: pass ? 'رجوع' : 'أعد الاختبار',
        outlined: true,
        onPressed: () => pass
            ? Navigator.pop(context)
            : Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => QuizScreen(level: widget.level))),
      ),
    ]);
  }
}
