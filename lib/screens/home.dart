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
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('السلام عليكم ورحمة الله', style: TextStyle(fontSize: 13, color: C.muted)),
              SizedBox(height: 2),
              Text(name == null || name.isEmpty ? greet : '$greet يا $name',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
          ),
          _chip(Icons.local_fire_department_rounded, '${ar(Progress.streak)} يوم'),
          SizedBox(width: 8),
          Pressable(
            onTap: () => _open(SettingsScreen()),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
              child: Icon(Icons.settings_rounded, color: C.text, size: 22),
            ),
          ),
        ]).enter(0),
        SizedBox(height: 18),
        _hero(ref, su, memS, last == null).enter(1),
        SizedBox(height: 14),
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
        ).enter(2),
        SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.98,
          children: [
            _tile(Icons.menu_book_rounded, C.green, C.greenSoft, 'الحفظ', () => widget.onTab(1)).enter(3),
            _tile(Icons.fact_check_rounded, C.coral, C.coralSoft, 'المراجعة', () => _open(ReviewScreen())).enter(4),
            _tile(Icons.mic_rounded, C.gold, C.goldSoft, 'التجويد', () => widget.onTab(2)).enter(5),
            _tile(Icons.local_library_rounded, C.blue, C.blueSoft, 'المكتبة', () => widget.onTab(3)).enter(6),
            _tile(Icons.chrome_reader_mode_rounded, C.purple, C.purpleSoft, 'المصحف', () => _open(TafsirIndexScreen())).enter(7),
            _tile(Icons.workspace_premium_rounded, C.gold, C.goldSoft, 'شهاداتي', () => _open(CertificatesScreen())).enter(8),
          ],
        ),
        if (next != null) ...[
          SizedBox(height: 14),
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
          ).enter(9),
        ],
        SizedBox(height: 14),
        _juzMap().enter(10),
      ],
    );
  }

  Widget _chip(IconData i, String t) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: C.surface2, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line)),
        child: Row(children: [
          Icon(i, size: 18, color: C.gold),
          SizedBox(width: 4),
          Text(t, style: TextStyle(color: C.gold, fontWeight: FontWeight.w600, fontSize: 13.5)),
        ]),
      );

  Widget _hero(AyahRef ref, Surah su, int memS, bool fresh) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [C.heroA, C.heroB],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: C.dark ? C.line2 : Colors.transparent),
          boxShadow: C.dark ? null : [BoxShadow(color: C.heroB.withOpacity(0.35), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(opacity: C.dark ? 0.07 : 0.12))),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Text(fresh ? 'ابدأ رحلتك مع القرآن' : 'وِردك الحالي',
                    style: TextStyle(fontSize: 13, color: C.heroAccent, fontWeight: FontWeight.w500)),
                Spacer(),
                Text('${ar(memS)} من ${ar(su.count)} آية', style: TextStyle(fontSize: 12, color: C.heroMuted)),
              ]),
              SizedBox(height: 12),
              Text('سورة ${su.name}', style: TextStyle(fontFamily: 'Amiri', fontSize: 30, fontWeight: FontWeight.w700, color: C.heroText)),
              SizedBox(height: 2),
              Text('من الآية ${ar(ref.a)} · الشيخ ${reciterById(Progress.reciter).name}',
                  style: TextStyle(fontSize: 13, color: C.heroMuted)),
              SizedBox(height: 14),
              ProgressBar(value: memS / su.count, height: 8, color: C.heroAccent),
              SizedBox(height: 16),
              GoldButton(
                label: fresh ? 'ابدأ الحفظ مع الشيخ' : 'أكمل الحفظ',
                icon: Icons.play_arrow_rounded,
                color: C.dark ? null : C.heroText,
                fg: C.dark ? null : C.heroB,
                onPressed: () => _open(HifzSession(surah: ref.s, startAyah: ref.a)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _tile(IconData icon, Color c, Color bg, String title, VoidCallback onTap) {
    return Panel(
      onTap: onTap,
      padding: EdgeInsets.all(10),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconBox(icon: icon, color: c, bg: bg, size: 46),
        SizedBox(height: 8),
        Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
      ]),
    );
  }

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
