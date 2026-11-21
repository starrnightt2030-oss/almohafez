import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../data/course.dart';
import 'hifz_session.dart';
import 'review.dart';
import 'certificate.dart';
import 'reader.dart';
import 'settings.dart';
import 'lesson.dart';
import 'tajweed.dart';
import '../services/voice.dart';
import '../widgets/illustrations.dart';

bool _welcomed = false;

class HomeScreen extends StatefulWidget {
  final void Function(int) onTab;
  const HomeScreen({super.key, required this.onTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (Progress.xp == 0 && Progress.memTotal == 0 && !_welcomed) {
      _welcomed = true;
      Future.delayed(Duration(milliseconds: 600), () => Voice.cue('welcome'));
    }
  }

  Future<void> _open(Widget page) async {
    await go(context, page);
    if (mounted) setState(() {});
  }

  /// أول درس تجويد لم يُتقن بعد.
  (Unit, int)? _nextLesson() {
    for (final u in Courses.tajweed) {
      for (var i = 0; i < u.lessons.length; i++) {
        if (!Progress.lessonPassed(u.lessons[i].id)) return (u, i);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final last = Progress.last;
    final ref = last ?? AyahRef(1, 1);
    final su = QuranData.surah(ref.s);
    final memS = Progress.memInSurah(ref.s);
    final name = Progress.name;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'صباح الخير' : 'مساء الخير';
    final next = _nextLesson();
    final fresh = last == null;
    return ListView(
      padding: EdgeInsets.only(bottom: 28),
      children: [
        // ── الرأس المرسوم + بطاقة الوِرد فوقه
        Stack(clipBehavior: Clip.none, children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: _AnimatedScene(),
          ),
          Positioned(
            top: 14,
            left: 20,
            right: 20,
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('السلام عليكم ورحمة الله', style: TextStyle(fontSize: 13, color: C.heroMuted)),
                  SizedBox(height: 2),
                  Text(name == null || name.isEmpty ? greet : 'أهلًا يا $name',
                      style: TextStyle(fontFamily: 'Ruqaa', fontSize: 30, height: 1.25, color: C.heroAccent)),
                ]),
              ),
              _heroChip(Icons.local_fire_department_rounded, '${ar(Progress.streak)} يوم'),
              SizedBox(width: 8),
              Pressable(
                onTap: () => _open(SettingsScreen()),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Icon(Icons.settings_rounded, color: C.heroText, size: 22),
                ),
              ),
            ]).enter(0),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 150, 20, 0),
            child: _wird(ref, su, memS, fresh).enter(1),
          ),
        ]),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _feature(0, 'الحفظ مع الشيخ', 'ردّد وراء الشيخ وتسميع تلقائي\nمع تصحيح حرفًا حرفًا', QuranStandPainter(),
                () => widget.onTab(1)).enter(2),
            SizedBox(height: 12),
            _feature(1, 'أكاديمية التجويد', '${ar(Courses.tajweed.length)} بابًا بدروس صوتية\nتدريب على آيات حقيقية وشهادات', MicPainter(),
                () => widget.onTab(2)).enter(3),
            SizedBox(height: 12),
            _feature(2, 'المكتبة الإسلامية', 'فقه، عقيدة، سيرة، وأحاديث\nمشروحة بالصوت والاختبارات', BooksPainter(),
                () => widget.onTab(3)).enter(4),
            SizedBox(height: 18),
            Row(children: [
              Expanded(child: _round(Icons.history_rounded, 'المراجعة', () => _open(ReviewScreen()))),
              Expanded(child: _round(Icons.chrome_reader_mode_rounded, 'المصحف', () => _open(TafsirIndexScreen()))),
              Expanded(child: _round(Icons.emoji_events_rounded, 'إنجازاتي', () => widget.onTab(4))),
              Expanded(child: _round(Icons.workspace_premium_rounded, 'شهاداتي', () => _open(CertificatesScreen()))),
            ]).enter(5),
            SizedBox(height: 18),
            Panel(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(Icons.stars_rounded, color: C.gold),
                SizedBox(width: 8),
                Text('المستوى ${ar(Progress.level)}', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(width: 12),
                Expanded(child: ProgressBar(value: Progress.levelProgress)),
                SizedBox(width: 12),
                Text('${ar(Progress.xp)} نقطة', style: TextStyle(color: C.muted, fontSize: 12.5)),
              ]),
            ).enter(6),
            if (next != null) ...[
              SizedBox(height: 12),
              Panel(
                onTap: () => _open(LessonScreen(unit: next.$1, index: next.$2)),
                child: Row(children: [
                  IconBox(icon: unitIcon(next.$1.icon), color: C.gold, bg: C.goldSoft),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('درسك التالي في التجويد · ${next.$1.title}', style: TextStyle(fontSize: 11.5, color: C.muted)),
                      SizedBox(height: 2),
                      Text(next.$1.lessons[next.$2].title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Icon(Icons.play_circle_rounded, color: C.gold, size: 30),
                ]),
              ).enter(7),
            ],
            SizedBox(height: 12),
            _juzMap().enter(8),
          ]),
        ),
      ],
    );
  }

  Widget _heroChip(IconData i, String t) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(children: [
          Icon(i, size: 18, color: C.heroAccent),
          SizedBox(width: 4),
          Text(t, style: TextStyle(color: C.heroAccent, fontWeight: FontWeight.w600, fontSize: 13.5)),
        ]),
      );

  /// بطاقة وِرد اليوم: حلقة تقدّم + السورة + زر الحفظ
  Widget _wird(AyahRef ref, Surah su, int memS, bool fresh) {
    final v = su.count == 0 ? 0.0 : memS / su.count;
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: C.dark ? C.gold.withOpacity(0.35) : C.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(C.dark ? 0.35 : 0.10), blurRadius: 30, offset: Offset(0, 14))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          ScoreRing(value: v, size: 64, label: '${ar((v * 100).round())}٪'),
          SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fresh ? 'ابدأ رحلتك مع القرآن' : 'وِردك الحالي', style: TextStyle(fontSize: 12, color: C.muted)),
              SizedBox(height: 2),
              Text('سورة ${su.name}', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.w700, color: C.gold, height: 1.3)),
              Text('من الآية ${ar(ref.a)} · ${ar(memS)} من ${ar(su.count)} آية',
                  style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
        ]),
        SizedBox(height: 14),
        GoldButton(
          label: fresh ? 'ابدأ الحفظ مع الشيخ' : 'تابع الحفظ مع الشيخ',
          icon: Icons.mic_rounded,
          onPressed: () => _open(HifzSession(surah: ref.s, startAyah: ref.a)),
        ),
        SizedBox(height: 8),
        Text('الشيخ ${reciterById(Progress.reciter).name}', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: C.muted)),
      ]),
    );
  }

  /// كارت قسم مرسوم (زي تصميم Claude Design)
  Widget _feature(int i, String title, String sub, CustomPainter art, VoidCallback onTap) {
    final (grad, titleC, subC, border) = featureColors(i);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 128,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: grad),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(C.dark ? 0.3 : 0.16), blurRadius: 22, offset: Offset(0, 10))],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: border, opacity: 0.12))),
          Row(children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontFamily: 'Amiri', fontSize: 25, fontWeight: FontWeight.w700, color: titleC, height: 1.25)),
                  SizedBox(height: 4),
                  Text(sub, style: TextStyle(fontSize: 12, color: subC, height: 1.55)),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: titleC.withOpacity(0.6)),
                      color: Colors.black.withOpacity(0.18),
                    ),
                    child: Text('دخول', style: TextStyle(fontSize: 12.5, color: titleC)),
                  ),
                ]),
              ),
            ),
            SizedBox(width: 140, height: 112, child: CustomPaint(painter: art)),
            SizedBox(width: 6),
          ]),
        ]),
      ),
    );
  }

  Widget _round(IconData icon, String t, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Column(children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.surface,
              border: Border.all(color: C.dark ? C.gold.withOpacity(0.7) : C.goldLine, width: 1.5),
            ),
            child: Icon(icon, color: C.gold, size: 24),
          ),
          SizedBox(height: 6),
          Text(t, style: TextStyle(fontSize: 11.5, color: C.textSoft)),
        ]),
      );

  Widget _juzMap() {
    var full = 0;
    final cells = <Widget>[];
    for (var j = 1; j <= 30; j++) {
      final refs = QuranData.juzAyahs(j);
      final f = Progress.memIn(refs) / refs.length;
      if (f >= 0.95) full++;
      final color = f >= 0.95 ? C.green : (f > 0 ? C.gold : C.line);
      cells.add(Tooltip(
        message: 'الجزء ${ar(j)}: ${ar((f * 100).round())}٪',
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color.withOpacity(f > 0 ? 1 : 0.6), borderRadius: BorderRadius.circular(6)),
          child: Text(ar(j), style: TextStyle(fontSize: 10, color: f > 0 ? C.bg : C.muted, fontWeight: FontWeight.w600)),
        ),
      ));
    }
    final placement = Progress.placement();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('خريطة حفظك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Spacer(),
          Text('${ar(full)} من ٣٠ جزءًا', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
        SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 10,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          children: cells,
        ),
        SizedBox(height: 10),
        Row(children: [
          _legend(C.green, 'متقن'),
          SizedBox(width: 14),
          _legend(C.gold, 'جارٍ حفظه'),
          SizedBox(width: 14),
          _legend(C.line, 'لم يُحفظ'),
        ]),
        if (placement != null) ...[
          SizedBox(height: 10),
          Text('نتيجة تحديد المستوى: تحفظ تقريبًا ${ar(placement)} جزءًا من آخر المصحف',
              style: TextStyle(fontSize: 12, color: C.green)),
        ],
      ]),
    );
  }

  Widget _legend(Color c, String t) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        SizedBox(width: 5),
        Text(t, style: TextStyle(fontSize: 11, color: C.muted)),
      ]);
}

/// مشهد الرأس مع تأرجح خفيف للفوانيس
class _AnimatedScene extends StatefulWidget {
  @override
  State<_AnimatedScene> createState() => _AnimatedSceneState();
}

class _AnimatedSceneState extends State<_AnimatedScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (C.t.id != 'ramadan') return CustomPaint(painter: HomeScenePainter(C.t.id));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(painter: HomeScenePainter(C.t.id, t: _c.value)),
    );
  }
}
