import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../services/audio.dart';
import '../widgets/tajweed_text.dart';
import 'hifz_session.dart';

/// فهرس السور للقراءة والتفسير.
class TafsirIndexScreen extends StatelessWidget {
  const TafsirIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'المصحف والتفسير',
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: QuranData.surahs.length,
        itemBuilder: (_, i) {
          final s = QuranData.surahs[i];
          return Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => go(context, ReaderScreen(surah: s.number)),
              child: Row(children: [
                SizedBox(
                  width: 38,
                  child: Text(ar(s.number), textAlign: TextAlign.center, style: TextStyle(color: C.gold, fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 8),
                Expanded(child: Text('سورة ${s.name}', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600))),
                Text('${s.type} · ${ar(s.count)}', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// قارئ المصحف بأحكام التجويد الملونة، مع التلاوة والتفسير الميسر.
class ReaderScreen extends StatefulWidget {
  final int surah;
  final int? startAyah;
  const ReaderScreen({super.key, required this.surah, this.startAyah});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _ready = TajweedData.ready;
  int? _playing;
  int _run = 0;
  bool _colors = Progress.tajweedColors;

  Surah get _su => QuranData.surah(widget.surah);

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
  void dispose() {
    _run++;
    Sheikh.stop();
    super.dispose();
  }

  Future<void> _playFrom(int a) async {
    final run = ++_run;
    for (var x = a; x <= _su.count; x++) {
      if (!mounted || run != _run) return;
      setState(() => _playing = x);
      try {
        await Sheikh.play(Progress.reciter, widget.surah, x);
      } catch (_) {
        if (mounted) toast(context, 'تعذّر التشغيل. تأكد من الاتصال بالإنترنت.');
        break;
      }
    }
    if (mounted && run == _run) setState(() => _playing = null);
  }

  Future<void> _stop() async {
    _run++;
    await Sheikh.stop();
    if (mounted) setState(() => _playing = null);
  }

  Future<void> _ayahSheet(int a) async {
    final ref = AyahRef(widget.surah, a);
    final tafsir = await TajweedData.tafsir(ref);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => ListView(controller: sc, padding: EdgeInsets.all(20), children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: C.line2, borderRadius: BorderRadius.circular(9)))),
          SizedBox(height: 14),
          Text('سورة ${_su.name} · الآية ${ar(a)}', textAlign: TextAlign.center, style: TextStyle(color: C.gold, fontWeight: FontWeight.w600)),
          SizedBox(height: 10),
          TajweedAyahView(ref: ref, fontSize: 24, tappable: false),
          SizedBox(height: 14),
          SectionTitle('التفسير الميسّر'),
          Text(tafsir, style: TextStyle(fontSize: 15.5, height: 2.0, color: C.textSoft)),
          SizedBox(height: 18),
          Row(children: [
            Expanded(
              child: GoldButton(
                label: 'استمع من هنا',
                icon: Icons.play_arrow_rounded,
                outlined: true,
                height: 46,
                onPressed: () {
                  Navigator.pop(ctx);
                  _playFrom(a);
                },
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: GoldButton(
                label: 'احفظها مع الشيخ',
                icon: Icons.mic_rounded,
                height: 46,
                onPressed: () {
                  Navigator.pop(ctx);
                  _stop();
                  go(context, HifzSession(surah: widget.surah, startAyah: a));
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBasmala = widget.surah != 1 && widget.surah != 9;
    return AppPage(
      title: 'سورة ${_su.name}',
      actions: [
        IconButton(
          tooltip: 'ألوان التجويد',
          icon: Icon(Icons.palette_rounded, color: _colors ? C.gold : C.muted),
          onPressed: () {
            setState(() => _colors = !_colors);
            Progress.setTajweedColors(_colors);
          },
        ),
      ],
      body: !_ready
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _su.count + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Column(children: [
                        Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: C.gold.withOpacity(0.4)),
                            gradient: LinearGradient(colors: [C.goldSoft, C.surface]),
                          ),
                          child: Column(children: [
                            Text('سورة ${_su.name}', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.w700, color: C.goldLight)),
                            Text('${_su.type} · ${ar(_su.count)} آية', style: TextStyle(fontSize: 12, color: C.muted)),
                          ]),
                        ),
                        if (_colors) Padding(padding: EdgeInsets.only(bottom: 10), child: TajweedLegend()),
                        if (showBasmala)
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', textAlign: TextAlign.center, style: quranStyle.copyWith(fontSize: 24)),
                          ),
                      ]);
                    }
                    final a = i;
                    final on = _playing == a;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(bottom: 8),
                      padding: EdgeInsets.fromLTRB(12, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: on ? C.highlight : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: on ? C.gold.withOpacity(0.6) : Colors.transparent),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        TajweedAyahView(ref: AyahRef(widget.surah, a), fontSize: 25, colors: _colors),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(
                            tooltip: 'تفسير الآية',
                            icon: Icon(Icons.menu_book_rounded, size: 20, color: C.muted),
                            onPressed: () => _ayahSheet(a),
                          ),
                          IconButton(
                            tooltip: 'استمع',
                            icon: Icon(on ? Icons.stop_circle_rounded : Icons.play_circle_rounded, size: 22, color: on ? C.gold : C.muted),
                            onPressed: () => on ? _stop() : _playFrom(a),
                          ),
                        ]),
                      ]),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: BoxDecoration(color: C.nav, border: Border(top: BorderSide(color: C.line))),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      _playing == null ? 'الشيخ ${reciterById(Progress.reciter).name}' : 'يتلو الآية ${ar(_playing!)}',
                      style: TextStyle(color: C.muted, fontSize: 13),
                    ),
                  ),
                  SizedBox(width: 160, child: GoldButton(
                    label: _playing == null ? 'تشغيل السورة' : 'إيقاف',
                    icon: _playing == null ? Icons.play_arrow_rounded : Icons.stop_rounded,
                    height: 44,
                    onPressed: () => _playing == null ? _playFrom(widget.startAyah ?? 1) : _stop(),
                  )),
                ]),
              ),
            ]),
    );
  }
}
