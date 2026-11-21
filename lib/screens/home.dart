import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import 'hifz_session.dart';
import 'review.dart';
import 'certificate.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int) onTab;
  const HomeScreen({super.key, required this.onTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final last = Progress.last;
    final ref = last ?? const AyahRef(1, 1);
    final su = QuranData.surah(ref.s);
    final memS = Progress.memInSurah(ref.s);
    final name = Progress.name;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'صباح الخير' : 'مساء الخير';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('السلام عليكم ورحمة الله', style: TextStyle(fontSize: 13, color: C.muted)),
              const SizedBox(height: 2),
              Text(name == null || name.isEmpty ? '$greet' : '$greet يا $name',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: C.surface2, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line)),
            child: Row(children: [
              const Icon(Icons.local_fire_department_outlined, size: 18, color: C.gold),
              const SizedBox(width: 4),
              Text('${ar(Progress.streak)} يوم',
                  style: const TextStyle(color: C.gold, fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        Panel(
          border: C.line2,
          radius: 24,
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text(last == null ? 'ابدأ رحلتك' : 'وِردك الحالي',
                  style: const TextStyle(fontSize: 13, color: C.gold, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${ar(memS)} من ${ar(su.count)} آية', style: const TextStyle(fontSize: 12, color: C.muted)),
            ]),
            const SizedBox(height: 12),
            Text('سورة ${su.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('من الآية ${ar(ref.a)} · مع الشيخ ${reciterById(Progress.reciter).name}',
                style: const TextStyle(fontSize: 13, color: C.muted)),
            const SizedBox(height: 14),
            ProgressBar(value: memS / su.count, height: 8),
            const SizedBox(height: 14),
            GoldButton(
              label: last == null ? 'ابدأ الحفظ' : 'أكمل الحفظ',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _open(HifzSession(surah: ref.s, startAyah: ref.a)),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _tile(Icons.menu_book_outlined, C.green, C.greenSoft, 'الحفظ والتسميع', 'ردّد وراء الشيخ',
                () => widget.onTab(1)),
            _tile(Icons.fact_check_outlined, C.coral, C.coralSoft, 'المراجعة والاختبار', 'سورة، جزء، حزب…',
                () => _open(const ReviewScreen())),
            _tile(Icons.mic_none_rounded, C.gold, C.goldSoft, 'أكاديمية التجويد',
                '${ar(Progress.tajweed.length)} من ٦ مستويات', () => widget.onTab(2)),
            _tile(Icons.auto_stories_outlined, C.blue, C.blueSoft, 'الفقه والحديث', 'تعلّم دينك بيسر',
                () => widget.onTab(3)),
          ],
        ),
        const SizedBox(height: 14),
        _juzMap(),
        const SizedBox(height: 14),
        Panel(
          onTap: () => _open(const CertificatesScreen()),
          child: Row(children: [
            const IconBox(icon: Icons.workspace_premium_outlined, color: C.gold, bg: C.goldSoft),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('شهاداتي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            Text(ar(Progress.certs.length), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_left, color: C.muted),
          ]),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, Color c, Color bg, String title, String sub, VoidCallback onTap) {
    return Panel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        IconBox(icon: icon, color: c, bg: bg, size: 40),
        const Spacer(),
        Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(sub, style: const TextStyle(fontSize: 12, color: C.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
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
      cells.add(GestureDetector(
        onTap: () => toast(context, 'الجزء ${ar(j)}: حفظت ${ar((f * 100).round())}٪'),
        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
      ));
    }
    final placement = Progress.placement();
    return Panel(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('خريطة حفظك', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${ar(full)} من ٣٠ جزءًا', style: const TextStyle(fontSize: 12, color: C.muted)),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: cells,
        ),
        const SizedBox(height: 10),
        Row(children: [
          _legend(C.green, 'متقن'),
          const SizedBox(width: 14),
          _legend(C.gold, 'جارٍ حفظه'),
          const SizedBox(width: 14),
          _legend(C.line, 'لم يُحفظ'),
        ]),
        if (placement != null) ...[
          const SizedBox(height: 10),
          Text('نتيجة تحديد المستوى: تحفظ تقريبًا ${ar(placement)} جزءًا من آخر المصحف',
              style: const TextStyle(fontSize: 12, color: C.green)),
        ],
      ]),
    );
  }

  Widget _legend(Color c, String t) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(t, style: const TextStyle(fontSize: 11, color: C.muted)),
      ]);
}
