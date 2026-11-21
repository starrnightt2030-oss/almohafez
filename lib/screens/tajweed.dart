import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/course.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import '../logic/drill.dart';
import 'certificate.dart';
import 'hifz_session.dart';
import '../widgets/tajweed_text.dart';
import 'lesson.dart';
import '../services/voice.dart';

int unitPassedCount(Unit u) => u.lessons.where((l) => Progress.lessonPassed(l.id)).length;
bool unitComplete(Unit u) => unitPassedCount(u) == u.lessons.length;

/// أكاديمية التجويد: أبواب متسلسلة، كل باب دروس واختبارات وتمارين وشهادة.
class TajweedScreen extends StatefulWidget {
  const TajweedScreen({super.key});

  @override
  State<TajweedScreen> createState() => _TajweedScreenState();
}

class _TajweedScreenState extends State<TajweedScreen> {
  static const _rowH = 118.0;

  Future<void> _openUnit(int i, List<Unit> units) async {
    final open = i == 0 || unitComplete(units[i - 1]);
    if (!open) {
      toast(context, 'أتقن دروس الباب السابق أولًا');
      return;
    }
    await go(context, UnitScreen(unit: units[i], kind: 'tajweed'));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final units = Courses.tajweed;
    final total = Courses.tajweedLessons;
    final done = units.fold<int>(0, (a, u) => a + unitPassedCount(u));
    var current = units.indexWhere((u) => !unitComplete(u));
    if (current < 0) current = units.length;
    return ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      HeroHeader(
        title: 'أكاديمية التجويد',
        subtitle: 'برواية حفص عن عاصم\n${ar(units.length)} بابًا · ${ar(total)} درسًا بالصوت والاختبارات',
        trailing: ScoreRing(value: total == 0 ? 0 : done / total, size: 84, label: '${ar(done)}', sub: 'من ${ar(total)}'),
      ).enter(0),
      SizedBox(height: 8),
      LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final centers = [for (var i = 0; i < units.length; i++) _center(i, w)];
        return SizedBox(
          height: _rowH * units.length + 24,
          child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: _PathPainter(centers, current))),
            for (var i = 0; i < units.length; i++) ..._node(i, units, centers[i], w, current),
          ]),
        );
      }),
    ]);
  }

  /// مكان كل محطة على الطريق المتعرّج (يمين ← شمال ← يمين ...)
  Offset _center(int i, double w) {
    const xs = [0.74, 0.5, 0.26, 0.5];
    return Offset(w * xs[i % 4], _rowH * i + 60);
  }

  List<Widget> _node(int i, List<Unit> units, Offset c, double w, int current) {
    final u = units[i];
    final open = i == 0 || unitComplete(units[i - 1]);
    final passed = unitPassedCount(u);
    final complete = passed == u.lessons.length;
    final isCur = i == current;
    final size = isCur ? 72.0 : 60.0;
    final ring = complete ? C.green : (open ? C.gold : C.line2);
    // البطاقة على الجهة الفاضية من المحطة
    final cardOnLeft = c.dx > w * 0.5 || (c.dx == w * 0.5 && i % 2 == 0);
    const cardW = 140.0;
    final double cardLeft = (cardOnLeft ? (c.dx - size / 2 - 12 - cardW) : (c.dx + size / 2 + 12)).clamp(0.0, w - cardW).toDouble();
    return [
      Positioned(
        left: c.dx - size / 2,
        top: c.dy - size / 2,
        child: Pressable(
          onTap: () => _openUnit(i, units),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: open
                  ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: complete ? [Color.lerp(C.green, Colors.white, 0.15)!, C.green] : C.goldGrad)
                  : null,
              color: open ? null : C.surface2,
              border: Border.all(color: isCur ? C.goldLight : ring.withOpacity(0.7), width: isCur ? 3 : 1.5),
              boxShadow: isCur ? [BoxShadow(color: C.gold.withOpacity(0.45), blurRadius: 24, spreadRadius: 2)] : null,
            ),
            child: Stack(alignment: Alignment.center, children: [
              if (open && !complete)
                SizedBox(
                  width: size - 8,
                  height: size - 8,
                  child: CircularProgressIndicator(
                    value: passed / u.lessons.length,
                    strokeWidth: 3,
                    backgroundColor: Colors.black.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation(C.onGold.withOpacity(0.8)),
                  ),
                ),
              Icon(
                complete ? Icons.check_rounded : (open ? unitIcon(u.icon) : Icons.lock_rounded),
                color: open ? (complete ? Colors.white : C.onGold) : C.muted,
                size: isCur ? 32 : 26,
              ),
            ]),
          ),
        ),
      ),
      Positioned(
        left: cardLeft,
        top: c.dy - 34,
        width: cardW,
        child: Pressable(
          onTap: () => _openUnit(i, units),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCur ? C.goldSoft : C.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isCur ? C.goldLine : C.line),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(isCur ? 'الباب ${ar(i + 1)} · ابدأ من هنا' : 'الباب ${ar(i + 1)}',
                  style: TextStyle(fontSize: 10.5, color: isCur ? C.gold : C.muted, fontWeight: isCur ? FontWeight.w600 : FontWeight.w400)),
              Text(u.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, height: 1.4, fontWeight: FontWeight.w600, color: open ? C.text : C.muted)),
              Row(children: [
                Text('${ar(passed)}/${ar(u.lessons.length)} دروس', style: TextStyle(fontSize: 10.5, color: complete ? C.green : C.muted)),
                if (Progress.unitScore(u.id) != null) ...[SizedBox(width: 4), Icon(Icons.workspace_premium_rounded, color: C.gold, size: 14)],
              ]),
            ]),
          ),
        ),
      ),
    ];
  }
}

/// الطريق المتعرّج بين المحطات: الجزء اللي خلص ذهبي، والباقي منقّط.
class _PathPainter extends CustomPainter {
  final List<Offset> pts;
  final int current;
  _PathPainter(this.pts, this.current);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final mid = (a.dy + b.dy) / 2;
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
      final done = i < current;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = done ? 6 : 4
        ..color = done ? C.gold.withOpacity(0.85) : C.line2;
      if (done) {
        canvas.drawPath(path, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..color = C.gold.withOpacity(0.12));
        canvas.drawPath(path, p);
      } else {
        for (final m in path.computeMetrics()) {
          var d = 0.0;
          while (d < m.length) {
            canvas.drawPath(m.extractPath(d, math.min(d + 8, m.length)), p);
            d += 16;
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter old) => old.current != current || old.pts.length != pts.length;
}

/// صفحة باب/قسم: الدروس، التمارين، الاختبار الشامل والشهادة.
class UnitScreen extends StatefulWidget {
  final Unit unit;
  final String kind; // tajweed | ilm
  const UnitScreen({super.key, required this.unit, required this.kind});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  bool get _seq => widget.kind == 'tajweed';

  @override
  void initState() {
    super.initState();
    if (widget.unit.drill.isNotEmpty && !TajweedData.ready) {
      TajweedData.load().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _drill() async {
    final items = Drill.make(widget.unit.drill, 10);
    if (items.isEmpty) {
      toast(context, 'جارٍ تجهيز التمارين…');
      return;
    }
    final pct = await go<int>(context, QuizScreen(title: 'تمرين تطبيقي: ${widget.unit.title}', items: items));
    if (pct != null && mounted) setState(() {});
  }

  Future<void> _exam() async {
    final r = math.Random();
    final all = <QItem>[
      for (final l in widget.unit.lessons)
        for (var k = 0; k < l.quiz.length; k++)
          QItem(l.quiz[k].q, l.quiz[k].options, l.quiz[k].answer, l.quiz[k].why, audio: 'assets/audio/quiz/${l.id}_${k + 1}'),
    ]..shuffle(r);
    final items = all.take(12).toList();
    if (widget.unit.drill.isNotEmpty) items.addAll(Drill.make(widget.unit.drill, 4));
    items.shuffle(r);
    final pct = await go<int>(context, QuizScreen(title: 'الاختبار الشامل: ${widget.unit.title}', items: items));
    if (pct == null || !mounted) return;
    if (pct >= passRatio * 100) {
      final first = Progress.unitScore(widget.unit.id) == null;
      await Progress.passUnit(widget.unit.id, pct);
      if (first) await Progress.addXp(100);
      if (!mounted) return;
      await issueCertificate(context, widget.kind, widget.unit.title, pct);
      Voice.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final passed = unitPassedCount(u);
    final complete = passed == u.lessons.length;
    final color = widget.kind == 'tajweed' ? C.gold : C.accent(u.color);
    return AppPage(
      title: u.title,
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        HeroHeader(
          title: u.title,
          subtitle: u.sub,
          color: color,
          trailing: ScoreRing(value: passed / u.lessons.length, size: 76, label: ar(passed), sub: 'من ${ar(u.lessons.length)}', color: color),
        ).enter(0),
        SizedBox(height: 16),
        SectionTitle('الدروس'),
        for (var k = 0; k < u.lessons.length; k++) _lessonTile(k, color).enter(1 + k),
        if (u.drill.isNotEmpty) ...[
          SizedBox(height: 8),
          SectionTitle('تمارين على آيات المصحف'),
          Panel(
            onTap: _drill,
            child: Row(children: [
              IconBox(icon: Icons.fitness_center_rounded, color: C.blue, bg: C.blueSoft),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تمرين تطبيقي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('حدّد الحكم في مواضع حقيقية من القرآن — أسئلة جديدة كل مرة', style: TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
              Icon(Icons.chevron_left_rounded, color: C.muted),
            ]),
          ).enter(2 + u.lessons.length),
        ],
        if (u.practice.isNotEmpty) ...[
          SizedBox(height: 8),
          SectionTitle('تدريب صوتي'),
          Panel(
            onTap: () async {
              await go(context, PracticeScreen(unit: u));
              if (mounted) setState(() {});
            },
            child: Row(children: [
              IconBox(icon: Icons.record_voice_over_rounded, color: C.green, bg: C.greenSoft),
              SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('اقرأ وصحّح مع الشيخ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('${ar(u.practice.where(Progress.practiced).length)} من ${ar(u.practice.length)} آيات متقنة', style: TextStyle(fontSize: 12, color: C.muted)),
                ]),
              ),
              Icon(Icons.chevron_left_rounded, color: C.muted),
            ]),
          ),
        ],
        SizedBox(height: 18),
        GoldButton(
          label: complete ? 'الاختبار الشامل والشهادة' : 'الاختبار الشامل (بعد إتقان كل الدروس)',
          icon: Icons.workspace_premium_rounded,
          onPressed: complete ? _exam : null,
          color: color,
        ),
        if (Progress.unitScore(u.id) != null)
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text('نتيجتك في الاختبار الشامل: ${ar(Progress.unitScore(u.id)!)}٪',
                textAlign: TextAlign.center, style: TextStyle(color: C.green)),
          ),
      ]),
    );
  }

  Widget _lessonTile(int k, Color color) {
    final l = widget.unit.lessons[k];
    final passed = Progress.lessonPassed(l.id);
    final open = !_seq || k == 0 || Progress.lessonPassed(widget.unit.lessons[k - 1].id);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Panel(
        color: open ? C.surface : C.deep,
        onTap: open
            ? () async {
                await go(context, LessonScreen(unit: widget.unit, index: k, quranExamples: widget.kind == 'tajweed'));
                if (mounted) setState(() {});
              }
            : () => toast(context, 'اجتز اختبار الدرس السابق أولًا'),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: passed ? C.greenSoft : (open ? C.accentSoft(widget.kind == 'tajweed' ? 'gold' : widget.unit.color) : C.bg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: passed
                ? Icon(Icons.check_rounded, color: C.green)
                : (open
                    ? Text(ar(k + 1), style: TextStyle(color: color, fontWeight: FontWeight.w700))
                    : Icon(Icons.lock_rounded, color: C.muted, size: 18)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: open ? C.text : C.muted)),
              SizedBox(height: 2),
              Text('${ar(l.paras.length)} فقرات صوتية · ${ar(l.quiz.length)} أسئلة${l.examples.isNotEmpty ? ' · ${ar(l.examples.length)} أمثلة' : ''}',
                  style: TextStyle(fontSize: 11.5, color: C.muted)),
            ]),
          ),
          if (passed) Text('${ar(Progress.lessonScore(l.id) ?? 0)}٪', style: TextStyle(color: C.green, fontSize: 12.5)),
          Icon(Icons.chevron_left_rounded, color: C.muted),
        ]),
      ),
    );
  }
}


/// تدريب صوتي على آيات مختارة تطبّق أحكام الباب.
class PracticeScreen extends StatefulWidget {
  final Unit unit;
  const PracticeScreen({super.key, required this.unit});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  bool _ready = TajweedData.ready;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      TajweedData.load().then((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final refs = widget.unit.practice;
    return AppPage(
      title: 'تدريب: ${widget.unit.title}',
      body: !_ready
          ? Center(child: CircularProgressIndicator())
          : ListView(padding: EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
              Text('اقرأ كل آية بصوتك وطبّق أحكام الباب. المس أي كلمة ملوّنة لمعرفة حكمها.',
                  textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.7)),
              SizedBox(height: 10),
              Center(child: TajweedLegend()),
              SizedBox(height: 12),
              for (var i = 0; i < refs.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Panel(
                    border: Progress.practiced(refs[i]) ? C.green : C.line,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        Text('سورة ${QuranData.surah(refs[i].s).name} · ${ar(refs[i].a)}', style: TextStyle(color: C.muted, fontSize: 12)),
                        Spacer(),
                        if (Progress.practiced(refs[i])) Tag('أتقنتها', fg: C.green, bg: C.greenSoft),
                      ]),
                      SizedBox(height: 6),
                      TajweedAyahView(ref: refs[i], fontSize: 24),
                      SizedBox(height: 10),
                      GoldButton(
                        label: 'اقرأ مع الشيخ',
                        icon: Icons.mic_rounded,
                        height: 44,
                        onPressed: () async {
                          await go(context, HifzSession(surah: refs[i].s, startAyah: refs[i].a, single: true));
                          if (mounted) setState(() {});
                        },
                      ),
                    ]),
                  ),
                ).enter(i),
            ]),
    );
  }
}
