import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import 'test_screen.dart';

/// المراجعة والاختبار: سورة، جزء، حزب، ربع، القرآن كاملًا، أو تحديد المستوى.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  void _go(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<int?> _pickNumber(BuildContext context, String title, int count, {String Function(int)? label}) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.7,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: label == null ? 5 : 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: label == null ? 1.2 : 3.2,
              ),
              itemCount: count,
              itemBuilder: (_, i) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(ctx, i + 1),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: C.deep, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.line)),
                  child: Text(label == null ? ar(i + 1) : label(i + 1),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('المراجعة والاختبار')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('اختر ما تريد مراجعته، والشيخ يختبرك بأسئلة «كمّل الآية» من مواضع مختلفة.',
            style: TextStyle(color: C.muted, height: 1.7)),
        const SizedBox(height: 16),
        _opt(Icons.menu_book_outlined, C.green, C.greenSoft, 'سورة', 'اختبار سورة كاملة مع شهادة', () async {
          final s = await _pickNumber(context, 'اختر السورة', 114, label: (n) => '${ar(n)}. ${QuranData.surah(n).name}');
          if (s != null && context.mounted) _go(context, TestScreen.surah(s));
        }),
        _opt(Icons.view_module_outlined, C.gold, C.goldSoft, 'جزء', '٣٠ جزءًا', () async {
          final j = await _pickNumber(context, 'اختر الجزء', 30);
          if (j != null && context.mounted) {
            _go(context, TestScreen.range('مراجعة الجزء ${ar(j)}', QuranData.juzAyahs(j), questions: 8));
          }
        }),
        _opt(Icons.view_agenda_outlined, C.blue, C.blueSoft, 'حزب (نصف جزء)', '٦٠ حزبًا', () async {
          final h = await _pickNumber(context, 'اختر الحزب', 60);
          if (h != null && context.mounted) {
            _go(context, TestScreen.range('مراجعة الحزب ${ar(h)}', QuranData.hizbAyahs(h), questions: 6));
          }
        }),
        _opt(Icons.crop_square, C.purple, const Color(0xFF2C2440), 'ربع حزب', '٢٤٠ ربعًا', () async {
          final h = await _pickNumber(context, 'اختر الحزب أولًا', 60);
          if (h == null || !context.mounted) return;
          final q = await _pickNumber(context, 'اختر الربع من الحزب ${ar(h)}', 4);
          if (q == null || !context.mounted) return;
          final rub = (h - 1) * 4 + q;
          _go(context, TestScreen.range('مراجعة الربع ${ar(q)} من الحزب ${ar(h)}', QuranData.rubAyahs(rub), questions: 4));
        }),
        _opt(Icons.all_inclusive, C.coral, C.coralSoft, 'القرآن كاملًا', 'أسئلة من كل المصحف', () {
          _go(context, TestScreen.range('مراجعة القرآن كاملًا', QuranData.all(), questions: 10));
        }),
        const SizedBox(height: 8),
        Panel(
          border: C.line2,
          onTap: () => _go(context, TestScreen.placement()),
          child: const Row(children: [
            IconBox(icon: Icons.insights_outlined, color: C.gold, bg: C.goldSoft),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تحديد المستوى', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text('نبدأ من جزء عمّ ونصعد حتى نعرف مقدار حفظك',
                    style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_left, color: C.muted),
          ]),
        ),
      ]),
    );
  }

  Widget _opt(IconData i, Color c, Color bg, String t, String s, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Panel(
          onTap: onTap,
          child: Row(children: [
            IconBox(icon: i, color: c, bg: bg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(s, style: const TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            const Icon(Icons.chevron_left, color: C.muted),
          ]),
        ),
      );
}
