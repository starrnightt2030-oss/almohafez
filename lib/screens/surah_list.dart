import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../logic/matcher.dart';
import 'hifz_session.dart';
import 'test_screen.dart';
import 'reader.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = Matcher.normalize(_q);
    final list = QuranData.surahs.where((s) => q.isEmpty || Matcher.normalize(s.name).contains(q) || '${s.number}' == _q.trim()).toList();
    return Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('الحفظ والتسميع', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 4),
          Text('حفظت ${ar(Progress.memTotal)} آية من ${ar(QuranData.total)}',
              style: TextStyle(fontSize: 13, color: C.muted)),
          SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            style: TextStyle(color: C.text),
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة',
              hintStyle: TextStyle(color: C.muted),
              prefixIcon: Icon(Icons.search, color: C.muted),
              filled: true,
              fillColor: C.surface,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.line)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.line)),
              focusedBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: C.gold)),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: 8),
          itemBuilder: (_, i) => _row(list[i]),
        ),
      ),
    ]);
  }

  Widget _row(Surah s) {
    final mem = Progress.memInSurah(s.number);
    final done = mem >= s.count;
    final hasCert = Progress.certs.any((c) => c.kind == 'surah' && c.title == 'سورة ${s.name}');
    return Panel(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _openSheet(s),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: done ? C.greenSoft : C.deep,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: done ? C.green : C.line),
          ),
          child: Text(ar(s.number),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: done ? C.green : C.text)),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(s.name, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              if (hasCert) ...[
                SizedBox(width: 6),
                Icon(Icons.workspace_premium, size: 16, color: C.gold),
              ],
            ]),
            SizedBox(height: 3),
            Text('${s.type} · ${ar(s.count)} آية', style: TextStyle(fontSize: 12, color: C.muted)),
            if (mem > 0) ...[
              SizedBox(height: 6),
              ProgressBar(value: mem / s.count, color: done ? C.green : C.gold, height: 4),
            ],
          ]),
        ),
        Icon(Icons.chevron_left, color: C.muted),
      ]),
    );
  }

  Future<void> _openSheet(Surah s) async {
    var start = Progress.firstUnmemorized(s.number);
    var reciter = Progress.reciter;
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.line2, borderRadius: BorderRadius.circular(9))),
            ),
            SizedBox(height: 16),
            Text('سورة ${s.name}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('${s.type} · ${ar(s.count)} آية · حفظت ${ar(Progress.memInSurah(s.number))}',
                style: TextStyle(color: C.muted, fontSize: 13)),
            SizedBox(height: 18),
            Text('ابدأ من الآية', style: TextStyle(fontSize: 13, color: C.muted)),
            Row(children: [
              Expanded(
                child: Slider(
                  value: start.toDouble(),
                  min: 1,
                  max: s.count.toDouble() < 1.5 ? 1.5 : s.count.toDouble(),
                  divisions: s.count > 1 ? s.count - 1 : 1,
                  activeColor: C.gold,
                  inactiveColor: C.line,
                  onChanged: s.count > 1 ? (v) => setS(() => start = v.round().clamp(1, s.count).toInt()) : null,
                ),
              ),
              SizedBox(width: 44, child: Text(ar(start), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: C.gold, fontWeight: FontWeight.w700))),
            ]),
            SizedBox(height: 8),
            Text('القارئ', style: TextStyle(fontSize: 13, color: C.muted)),
            SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final r in reciters)
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setS(() => reciter = r.id),
                        child: Container(
                          width: 168,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: reciter == r.id ? C.goldSoft : C.deep,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: reciter == r.id ? C.gold : C.line),
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text(r.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: C.muted)),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),
            GoldButton(label: 'ابدأ الحفظ مع الشيخ', icon: Icons.play_arrow_rounded, onPressed: () => Navigator.pop(ctx, 'hifz')),
            SizedBox(height: 10),
            Row(children: [
              Expanded(child: GoldButton(label: 'اختبر حفظك', icon: Icons.fact_check_rounded, outlined: true, onPressed: () => Navigator.pop(ctx, 'test'))),
              SizedBox(width: 10),
              Expanded(child: GoldButton(label: 'اقرأ وتدبّر', icon: Icons.chrome_reader_mode_rounded, outlined: true, onPressed: () => Navigator.pop(ctx, 'read'))),
            ]),
          ]),
        );
      }),
    );
    if (!mounted || action == null) return;
    await Progress.setReciter(reciter);
    if (!mounted) return;
    if (action == 'hifz') {
      await go(context, HifzSession(surah: s.number, startAyah: start));
    } else if (action == 'read') {
      await go(context, ReaderScreen(surah: s.number, startAyah: start));
    } else {
      await go(context, TestScreen.surah(s.number));
    }
    if (mounted) setState(() {});
  }
}
