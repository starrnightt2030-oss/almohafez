import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import '../services/voice.dart';
import 'hifz_session.dart';

/// التقرير الأسبوعي: حفظك ونشاطك في آخر ٧ أيام مقارنةً بالأسبوع اللي قبله، والآيات اللي محتاجة مراجعة.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () => Voice.cue('weekly_report'));
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [for (var k = 6; k >= 0; k--) today.subtract(Duration(days: k))];
    final prev = [for (var k = 13; k >= 7; k--) today.subtract(Duration(days: k))];
    final newThis = days.fold<int>(0, (a, d) => a + Progress.newOn(d));
    final newPrev = prev.fold<int>(0, (a, d) => a + Progress.newOn(d));
    final active = days.where(Progress.activeOn).length;
    final maxDay = days.map(Progress.newOn).fold<int>(1, (a, b) => b > a ? b : a);
    final weak = Progress.mistakes.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    const names = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];
    final diff = newThis - newPrev;
    return AppPage(
      title: 'تقرير الأسبوع',
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        HeroHeader(
          title: active >= 5 ? 'أسبوع مبارك!' : (active >= 2 ? 'بداية طيبة' : 'هيا نعود للوِرد'),
          subtitle: 'نشطت ${ar(active)} من ٧ أيام · السلسلة ${ar(Progress.streak)} يوم\n'
              '${diff > 0 ? 'حفظت ${ar(diff)} آية أكثر من الأسبوع الماضي' : (diff < 0 ? 'أقل من الأسبوع الماضي بـ ${ar(-diff)} آية' : 'مثل الأسبوع الماضي')}',
          trailing: ScoreRing(value: active / 7, size: 82, label: ar(newThis), sub: 'آية جديدة'),
        ).enter(0),
        SizedBox(height: 14),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('الآيات الجديدة يومًا بيوم', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final d in days)
                  Expanded(
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Text(ar(Progress.newOn(d)), style: TextStyle(fontSize: 11, color: C.muted)),
                      SizedBox(height: 4),
                      AnimatedContainer(
                        duration: Duration(milliseconds: 500),
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        height: 8 + 82 * Progress.newOn(d) / maxDay,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8), bottom: Radius.circular(3)),
                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: Progress.activeOn(d) ? C.goldGrad : [C.line, C.line]),
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(names[d.weekday - 1], style: TextStyle(fontSize: 9.5, color: C.muted)),
                    ]),
                  ),
              ]),
            ),
          ]),
        ).enter(1),
        SizedBox(height: 12),
        Row(children: [
          Expanded(child: _stat(ar(Progress.memTotal), 'إجمالي المحفوظ', C.gold)),
          SizedBox(width: 10),
          Expanded(child: _stat(ar(Progress.lessonsPassed), 'درس متقن', C.green)),
          SizedBox(width: 10),
          Expanded(child: _stat(ar(Progress.level), 'المستوى', C.blue)),
        ]).enter(2),
        SizedBox(height: 18),
        SectionTitle('آيات تحتاج مراجعة'),
        if (weak.isEmpty)
          Panel(child: Text('ما شاء الله، لا توجد آيات متعثّرة. استمر في المراجعة حتى يثبت الحفظ.', style: TextStyle(color: C.muted, height: 1.7)))
        else
          for (final e in weak.take(6)) _weak(e.key, e.value),
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

  Widget _weak(String key, int n) {
    final p = key.split(':');
    final r = AyahRef(int.parse(p[0]), int.parse(p[1]));
    final words = QuranData.simpleWords(r);
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: () async {
          await go(context, HifzSession(surah: r.s, startAyah: r.a, single: true));
          if (mounted) setState(() {});
        },
        child: Row(children: [
          IconBox(icon: Icons.replay_rounded, color: C.red, bg: C.redSoft),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${QuranData.surah(r.s).name} · الآية ${ar(r.a)}', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(words.take(5).join(' ') + (words.length > 5 ? ' …' : ''),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: C.muted)),
            ]),
          ),
          Tag('${ar(n)} مرة', fg: C.red, bg: C.redSoft),
        ]),
      ),
    );
  }
}
