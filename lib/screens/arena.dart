import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/course.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import '../logic/drill.dart';
import 'lesson.dart';
import 'test_screen.dart';
import 'certificate.dart';
import 'weekly_report.dart';
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
  void initState() {
    super.initState();
    // وسام جديد أو هدف اليوم اكتمل ← تهنئة بالصوت (مرة واحدة)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final earned = _badges().where((b) => b.$3).length;
      if (earned > Progress.badgesSeen) {
        await Progress.setBadgesSeen(earned);
        Voice.cue('badge');
      } else if (Progress.todayNew >= Progress.dailyGoal && !Progress.goalCheered) {
        await Progress.setGoalCheered();
        Voice.cue('goal_done');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = math.Random();
    return ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      Row(children: [
        Expanded(child: Text('إنجازاتي', style: TextStyle(fontFamily: 'Ruqaa', fontSize: 30, height: 1.3, color: C.gold))),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.goldLine)),
          child: Text('المستوى ${ar(Progress.level)} · ${_rank()}', style: TextStyle(fontSize: 12.5, color: C.gold, fontWeight: FontWeight.w600)),
        ),
      ]).enter(0),
      SizedBox(height: 12),
      _goal().enter(1),
      SizedBox(height: 12),
      _week().enter(2),
      SizedBox(height: 12),
      Row(children: [
        Expanded(child: _stat(ar(Progress.memTotal), 'آية محفوظة', C.gold)),
        SizedBox(width: 10),
        Expanded(child: _stat(ar(Progress.lessonsPassed), 'درس تجويد وعلم', C.green)),
        SizedBox(width: 10),
        Expanded(child: _stat(ar(Progress.xp), 'نقطة', C.blue)),
      ]).enter(3),
      SizedBox(height: 16),
      SectionTitle('الأوسمة', trailing: Text('${ar(_badges().where((b) => b.$3).length)} من ${ar(_badges().length)}', style: TextStyle(fontSize: 12, color: C.gold))),
      SizedBox(
        height: 104,
        child: ListView(scrollDirection: Axis.horizontal, children: [for (final b in _badges()) _badge(b)]),
      ).enter(4),
      SizedBox(height: 10),
      GoldButton(
        label: 'شهاداتي (${ar(Progress.certs.length)}) · عرض ومشاركة',
        icon: Icons.workspace_premium_rounded,
        outlined: true,
        onPressed: () async {
          await go(context, CertificatesScreen());
          if (mounted) setState(() {});
        },
      ).enter(5),
      SizedBox(height: 10),
      GoldButton(
        label: 'تقرير الأسبوع',
        icon: Icons.insights_rounded,
        outlined: true,
        onPressed: () async {
          await go(context, WeeklyReportScreen());
          if (mounted) setState(() {});
        },
      ).enter(6),
      SizedBox(height: 18),
      SectionTitle('المسابقات'),
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

  String _rank() {
    final l = Progress.level;
    if (l >= 20) return 'حافظ متقن';
    if (l >= 10) return 'حافظ مجتهد';
    if (l >= 4) return 'طالب مثابر';
    return 'بداية الطريق';
  }

  Widget _goal() {
    final goal = Progress.dailyGoal;
    final n = Progress.todayNew;
    final v = goal == 0 ? 1.0 : (n / goal).clamp(0.0, 1.0).toDouble();
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [C.heroA, C.heroB]),
        border: Border.all(color: C.heroAccent.withOpacity(0.45)),
      ),
      child: Row(children: [
        ScoreRing(value: v, size: 104, label: '${ar((v * 100).round())}٪', sub: 'هدف اليوم', color: C.heroAccent),
        SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('حفظ جديد اليوم', style: TextStyle(fontSize: 12, color: C.heroMuted)),
            Text('${ar(n)} من ${ar(goal)} آيات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: C.heroText)),
            SizedBox(height: 8),
            Text(n >= goal ? 'أتممت وِردك اليوم، بارك الله فيك' : 'بقي ${ar(goal - n)} آيات لإكمال هدفك',
                style: TextStyle(fontSize: 12, color: C.heroAccent)),
            SizedBox(height: 6),
            GestureDetector(
              onTap: _pickGoal,
              child: Text('تغيير الهدف', style: TextStyle(fontSize: 12, color: C.heroMuted, decoration: TextDecoration.underline)),
            ),
          ]),
        ),
      ]),
    );
  }

  Future<void> _pickGoal() async {
    final v = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          for (final g in [3, 5, 10, 15, 20])
            ChoiceChip(label: Text('${ar(g)} آيات'), selected: Progress.dailyGoal == g, onSelected: (_) => Navigator.pop(ctx, g)),
          SizedBox(width: double.infinity, height: 16),
        ]),
      ),
    );
    if (v != null) {
      await Progress.setDailyGoal(v);
      if (mounted) setState(() {});
    }
  }

  Widget _week() {
    const names = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    final today = DateTime.now();
    final days = [for (var k = 6; k >= 0; k--) today.subtract(Duration(days: k))];
    return Panel(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('سلسلة الأيام', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          Spacer(),
          Icon(Icons.local_fire_department_rounded, color: C.coral, size: 18),
          SizedBox(width: 4),
          Text('${ar(Progress.streak)} يومًا متتاليًا', style: TextStyle(fontSize: 13, color: C.coral, fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final d in days)
            Column(children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: Progress.activeOn(d) ? LinearGradient(colors: [Color.lerp(C.coral, Colors.white, 0.25)!, C.coral]) : null,
                  border: Progress.activeOn(d)
                      ? null
                      : Border.all(color: d.day == today.day ? C.coral : C.line2, width: d.day == today.day ? 2 : 1),
                ),
                child: Progress.activeOn(d)
                    ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
                    : Text(ar(d.day), style: TextStyle(fontSize: 12, color: C.muted)),
              ),
              SizedBox(height: 4),
              Text(names[d.weekday - 1], style: TextStyle(fontSize: 9.5, color: C.muted)),
            ]),
        ]),
      ]),
    );
  }

  Widget _stat(String v, String t, Color c) => Panel(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(children: [
          Text(v, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: c)),
          SizedBox(height: 2),
          Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: C.muted)),
        ]),
      );

  /// (الاسم، الأيقونة، مكتسب؟)
  List<(String, IconData, bool)> _badges() {
    final amma = QuranData.juzAyahs(30);
    return [
      ('أول آية', Icons.auto_awesome_rounded, Progress.memTotal >= 1),
      ('٣ أيام متتالية', Icons.local_fire_department_rounded, Progress.streak >= 3),
      ('أسبوع كامل', Icons.calendar_month_rounded, Progress.streak >= 7),
      ('١٠٠ آية', Icons.menu_book_rounded, Progress.memTotal >= 100),
      ('جزء عمّ', Icons.star_rounded, Progress.memIn(amma) >= amma.length),
      ('١٠ دروس', Icons.school_rounded, Progress.lessonsPassed >= 10),
      ('أول شهادة', Icons.workspace_premium_rounded, Progress.certs.isNotEmpty),
      ('شهر كامل', Icons.emoji_events_rounded, Progress.streak >= 30),
    ];
  }

  Widget _badge((String, IconData, bool) b) => Container(
        width: 82,
        margin: EdgeInsetsDirectional.only(end: 10),
        child: Opacity(
          opacity: b.$3 ? 1 : 0.38,
          child: Column(children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: b.$3 ? C.goldGrad : [C.surface2, C.surface]),
                border: Border.all(color: b.$3 ? C.goldLight : C.line2, width: 1.5),
                boxShadow: b.$3 ? [BoxShadow(color: C.gold.withOpacity(0.35), blurRadius: 14)] : null,
              ),
              child: Icon(b.$3 ? b.$2 : Icons.lock_rounded, color: b.$3 ? C.onGold : C.muted, size: 28),
            ),
            SizedBox(height: 6),
            Text(b.$1, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11)),
          ]),
        ),
      );

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
