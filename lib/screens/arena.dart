import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/course.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import '../logic/drill.dart';
import 'lesson.dart';
import 'test_screen.dart';
import '../services/voice.dart';

/// المسابقات: تحدي اليوم، مسابقات حسب الفرع، والمجموعات (قريبًا).
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  List<QItem> _pool(List<Unit> units) => [
        for (final u in units)
          for (final l in u.lessons)
            for (var k = 0; k < l.quiz.length; k++)
              QItem(l.quiz[k].q, l.quiz[k].options, l.quiz[k].answer, l.quiz[k].why, audio: 'assets/audio/quiz/${l.id}_${k + 1}'),
      ];

  Future<void> _run(String title, List<QItem> items) async {
    if (items.isEmpty) {
      toast(context, 'جارٍ التجهيز، حاول بعد لحظة');
      return;
    }
    final pct = await go<int>(context, QuizScreen(title: title, items: items));
    if (pct != null) {
      await Progress.setBestArena(pct);
      if (mounted) setState(() {});
    }
  }

  Future<void> _daily() async {
    await TajweedData.load();
    final now = DateTime.now();
    final seed = now.year * 1000 + now.month * 50 + now.day;
    final r = math.Random(seed);
    final tj = _pool(Courses.tajweed)..shuffle(r);
    final lib = _pool(Courses.library)..shuffle(r);
    final items = [...tj.take(4), ...lib.take(4), ...Drill.make(['ikhfa', 'idghaam_ghunnah', 'qalqalah', 'madd_6', 'iqlab', 'madd_muttasil'], 2, seed: seed)];
    items.shuffle(r);
    await Voice.cue('daily_challenge');
    await _run('تحدي اليوم', items);
  }

  @override
  Widget build(BuildContext context) {
    final r = math.Random();
    return ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      HeroHeader(
        title: 'المسابقات',
        subtitle: '«وفي ذلك فليتنافس المتنافسون»\nالمستوى ${ar(Progress.level)} · ${ar(Progress.xp)} نقطة',
        trailing: ScoreRing(value: Progress.levelProgress, size: 80, label: ar(Progress.level), sub: 'المستوى'),
      ).enter(0),
      SizedBox(height: 16),
      Panel(
        gradient: LinearGradient(colors: [C.goldSoft, C.surface]),
        border: C.goldLine,
        onTap: _daily,
        child: Row(children: [
          IconBox(icon: Icons.emoji_events_rounded, color: C.gold, bg: C.goldSoft, size: 54),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تحدي اليوم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text('١٠ أسئلة في التجويد والفقه والآيات — تتجدد كل يوم', style: TextStyle(fontSize: 12, color: C.muted)),
              SizedBox(height: 6),
              Text('أفضل نتيجة: ${ar(Progress.bestArena)}٪', style: TextStyle(fontSize: 12, color: C.gold)),
            ]),
          ),
          Icon(Icons.chevron_left_rounded, color: C.muted),
        ]),
      ).enter(1),
      SizedBox(height: 18),
      SectionTitle('مسابقات حسب الفرع'),
      _tile(Icons.mic_rounded, C.gold, C.goldSoft, 'مسابقة التجويد', 'أسئلة من كل أبواب التجويد', () {
        final p = _pool(Courses.tajweed)..shuffle(r);
        _run('مسابقة التجويد', p.take(10).toList());
      }).enter(2),
      _tile(Icons.fitness_center_rounded, C.blue, C.blueSoft, 'حدّد الحكم', 'أحكام على آيات حقيقية من المصحف', () async {
        await TajweedData.load();
        _run('حدّد الحكم', Drill.make(['ikhfa', 'idghaam_ghunnah', 'idghaam_no_ghunnah', 'iqlab', 'ikhfa_shafawi', 'qalqalah', 'madd_muttasil', 'madd_munfasil', 'madd_6', 'ghunnah'], 10));
      }).enter(3),
      _tile(Icons.auto_stories_rounded, C.green, C.greenSoft, 'مسابقة العلوم الشرعية', 'العقيدة والفقه والآداب والأذكار', () {
        final p = _pool(Courses.library)..shuffle(r);
        _run('مسابقة العلوم الشرعية', p.take(10).toList());
      }).enter(4),
      _tile(Icons.menu_book_rounded, C.coral, C.coralSoft, 'مسابقة الحفظ', 'كمّل الآية من جزء عمّ بصوتك', () {
        go(context, TestScreen.range('مسابقة الحفظ: جزء عمّ', QuranData.juzAyahs(30), questions: 6));
      }).enter(5),
      SizedBox(height: 18),
      SectionTitle('المجموعات'),
      Panel(
        border: C.line2,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconBox(icon: Icons.groups_rounded, color: C.purple, bg: C.purpleSoft),
            SizedBox(width: 12),
            Expanded(child: Text('احفظ مع عائلتك وأصدقائك', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
            Tag('قريبًا', fg: C.goldLight, bg: C.goldSoft),
          ]),
          SizedBox(height: 12),
          for (final t in [
            'أنشئ مجموعة وادعُ أصدقاءك برابط واحد',
            'حدد سورة أو جزءًا أو بابًا ومدة يقسّمها التطبيق لوِرد يومي',
            'تمديد المدة بتصويت الأعضاء، وتشجيع يومي',
            'اختبار نهائي عادل وترتيب بالحفظ والتجويد والالتزام',
          ])
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: C.purple)),
                SizedBox(width: 8),
                Expanded(child: Text(t, style: TextStyle(color: C.muted, fontSize: 13, height: 1.6))),
              ]),
            ),
        ]),
      ).enter(6),
    ]);
  }

  Widget _tile(IconData i, Color c, Color bg, String t, String s, VoidCallback onTap) => Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Panel(
          onTap: onTap,
          child: Row(children: [
            IconBox(icon: i, color: c, bg: bg),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(s, style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_left_rounded, color: C.muted),
          ]),
        ),
      );
}
