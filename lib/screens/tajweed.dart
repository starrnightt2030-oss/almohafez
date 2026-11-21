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
  @override
  Widget build(BuildContext context) {
    final units = Courses.tajweed;
    final total = Courses.tajweedLessons;
    final done = units.fold<int>(0, (a, u) => a + unitPassedCount(u));
    return ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      HeroHeader(
        title: 'أكاديمية التجويد',
        subtitle: 'برواية حفص عن عاصم\n${ar(units.length)} بابًا · ${ar(total)} درسًا بالصوت والاختبارات',
        trailing: ScoreRing(value: total == 0 ? 0 : done / total, size: 84, label: '${ar(done)}', sub: 'من ${ar(total)}'),
      ).enter(0),
      SizedBox(height: 18),
      for (var i = 0; i < units.length; i++) _unit(i, units).enter(1 + i),
    ]);
  }

  Widget _unit(int i, List<Unit> units) {
    final u = units[i];
    final open = i == 0 || unitComplete(units[i - 1]);
    final passed = unitPassedCount(u);
    final complete = passed == u.lessons.length;
    final exam = Progress.unitScore(u.id);
    final current = open && !complete;
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Panel(
        onTap: open
            ? () async {
                await go(context, UnitScreen(unit: u, kind: 'tajweed'));
                if (mounted) setState(() {});
              }
            : () => toast(context, 'أتقن دروس الباب السابق أولًا'),
        border: current ? C.goldLine : C.line,
        gradient: current ? LinearGradient(colors: [C.goldSoft, C.surface]) : null,
        color: open ? C.surface : C.deep,
        child: Row(children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: passed / u.lessons.length,
                strokeWidth: 3,
                backgroundColor: C.line,
                valueColor: AlwaysStoppedAnimation(complete ? C.green : C.gold),
              ),
            ),
            Icon(open ? unitIcon(u.icon) : Icons.lock_rounded, color: open ? (complete ? C.green : C.gold) : C.muted, size: 24),
          ]),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الباب ${ar(i + 1)}', style: TextStyle(fontSize: 11.5, color: C.muted)),
              Text(u.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: open ? C.text : C.muted)),
              SizedBox(height: 3),
              Text(u.sub, style: TextStyle(fontSize: 12, color: C.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${ar(passed)}/${ar(u.lessons.length)}', style: TextStyle(color: complete ? C.green : C.gold, fontWeight: FontWeight.w700)),
            if (exam != null) Icon(Icons.workspace_premium_rounded, color: C.gold, size: 18),
          ]),
        ]),
      ),
    );
  }
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
