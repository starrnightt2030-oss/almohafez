import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../data/course.dart';
import '../data/hadith.dart';
import '../data/progress.dart';
import '../logic/matcher.dart';
import '../services/voice.dart';
import 'tajweed.dart';
import 'reader.dart';

/// المكتبة الإسلامية: العلوم الشرعية، الحديث الشريف، التفسير.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _ready = Hadiths.books.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_ready) {
      Hadiths.load().then((_) {
        if (mounted) setState(() => _ready = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = Courses.library;
    return ListView(padding: EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      Row(children: [
        Expanded(child: Text('المكتبة الإسلامية', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700))),
        _iconBtn(Icons.search_rounded, 'بحث في الأحاديث', () => go(context, HadithSearchScreen())),
        SizedBox(width: 8),
        _iconBtn(Icons.bookmark_rounded, 'المحفوظات', () async {
          await go(context, FavoritesScreen());
          if (mounted) setState(() {});
        }),
      ]).enter(0),
      SizedBox(height: 14),
      if (_ready) _today().enter(1),
      SizedBox(height: 18),
      SectionTitle('العلوم الشرعية'),
      GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.05),
        itemCount: cats.length,
        itemBuilder: (_, i) => _cat(cats[i]).enter(2 + i),
      ),
      SizedBox(height: 18),
      SectionTitle('الحديث الشريف'),
      if (!_ready) Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
      if (_ready)
        for (var i = 0; i < Hadiths.books.length; i++) _book(Hadiths.books[i]).enter(4 + i),
      SizedBox(height: 18),
      SectionTitle('تفسير القرآن'),
      Panel(
        onTap: () => go(context, TafsirIndexScreen()),
        child: Row(children: [
          IconBox(icon: Icons.menu_book_rounded, color: C.green, bg: C.greenSoft),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('التفسير الميسّر', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('تفسير مختصر وواضح لكل آيات القرآن الكريم', style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
          Icon(Icons.chevron_left_rounded, color: C.muted),
        ]),
      ).enter(8),
    ]);
  }

  Widget _iconBtn(IconData i, String tip, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Tooltip(
          message: tip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
            child: Icon(i, color: C.text, size: 22),
          ),
        ),
      );

  Widget _today() {
    final h = Hadiths.today();
    return Panel(
      radius: 24,
      padding: EdgeInsets.zero,
      border: C.goldLine,
      onTap: () => _openHadith(context, [h], 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(opacity: 0.06))),
          Padding(
            padding: EdgeInsets.all(18),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('حديث اليوم', style: TextStyle(fontSize: 12.5, color: C.gold, fontWeight: FontWeight.w600)),
                Spacer(),
                if (h.title != null) Tag(h.title!, fg: C.goldLight, bg: C.goldSoft),
              ]),
              SizedBox(height: 10),
              Text(_matn(h.text), maxLines: 4, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: 'Amiri', fontSize: 19, height: 1.9)),
              if (h.sharh != null) ...[
                SizedBox(height: 8),
                Text(h.sharh!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: C.muted, fontSize: 12.5, height: 1.7)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _cat(Unit u) {
    final done = unitPassedCount(u);
    final c = C.accent(u.color);
    return Panel(
      padding: EdgeInsets.all(14),
      onTap: () async {
        await go(context, UnitScreen(unit: u, kind: 'ilm'));
        if (mounted) setState(() {});
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconBox(icon: unitIcon(u.icon), color: c, bg: C.accentSoft(u.color), size: 42),
          Spacer(),
          if (Progress.unitScore(u.id) != null) Icon(Icons.workspace_premium_rounded, color: c, size: 20),
        ]),
        Spacer(),
        Text(u.title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
        SizedBox(height: 3),
        Text(u.sub, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: C.muted, height: 1.5)),
        SizedBox(height: 8),
        ProgressBar(value: done / u.lessons.length, color: c, height: 4),
      ]),
    );
  }

  Widget _book(HadithBook b) {
    final icon = b.id == 'qudsi'
        ? Icons.auto_awesome_rounded
        : (b.id == 'riyad' ? Icons.local_florist_rounded : (b.id == 'essential' ? Icons.star_rounded : Icons.format_quote_rounded));
    final color = b.id == 'qudsi' ? C.purple : (b.id == 'riyad' ? C.green : (b.id == 'essential' ? C.coral : C.gold));
    final soft = b.id == 'qudsi' ? C.purpleSoft : (b.id == 'riyad' ? C.greenSoft : (b.id == 'essential' ? C.coralSoft : C.goldSoft));
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: () => go(context, HadithBookScreen(book: b)),
        child: Row(children: [
          IconBox(icon: icon, color: color, bg: soft, size: 46),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.title, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('${ar(b.count)} حديثًا${b.sections.length > 1 ? ' · ${ar(b.sections.length)} كتابًا' : ''}',
                  style: TextStyle(fontSize: 12, color: C.muted)),
            ]),
          ),
          Icon(Icons.chevron_left_rounded, color: C.muted),
        ]),
      ),
    );
  }
}

/// متن الحديث بدون الإسناد الطويل للعرض المختصر.
String _matn(String t) {
  final i = t.indexOf('"');
  if (i > 0 && i < 220) return t.substring(i).replaceAll('"', '').trim();
  return t;
}

void _openHadith(BuildContext context, List<HadithItem> list, int index) =>
    go(context, HadithView(items: list, index: index));

class HadithBookScreen extends StatelessWidget {
  final HadithBook book;
  const HadithBookScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    if (book.sections.length == 1) {
      return HadithListScreen(title: book.title, items: book.sections.first.items, desc: book.desc);
    }
    return AppPage(
      title: book.title,
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
        HeroHeader(title: book.title, subtitle: '${book.author}\n${book.desc}', color: C.green).enter(0),
        SizedBox(height: 14),
        for (var i = 0; i < book.sections.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Panel(
              onTap: () => go(context, HadithListScreen(title: book.sections[i].title, items: book.sections[i].items)),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.greenSoft, borderRadius: BorderRadius.circular(11)),
                  child: Text(ar(i + 1), style: TextStyle(color: C.green, fontWeight: FontWeight.w700)),
                ),
                SizedBox(width: 12),
                Expanded(child: Text(book.sections[i].title, style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500))),
                Text(ar(book.sections[i].items.length), style: TextStyle(color: C.muted, fontSize: 12.5)),
                Icon(Icons.chevron_left_rounded, color: C.muted),
              ]),
            ),
          ).enter(1 + i),
      ]),
    );
  }
}

class HadithListScreen extends StatelessWidget {
  final String title;
  final List<HadithItem> items;
  final String? desc;
  const HadithListScreen({super.key, required this.title, required this.items, this.desc});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: title,
      body: ListView.builder(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: items.length + (desc == null ? 0 : 1),
        itemBuilder: (_, k) {
          if (desc != null && k == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: HeroHeader(title: title, subtitle: desc!, color: C.purple),
            );
          }
          final i = desc == null ? k : k - 1;
          final h = items[i];
          return Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Panel(
              onTap: () => _openHadith(context, items, i),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(10)),
                  child: Text(ar(h.n), style: TextStyle(color: C.gold, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (h.title != null) Text(h.title!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                    if (h.title != null) SizedBox(height: 4),
                    Text(_matn(h.text), maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Amiri', fontSize: 15.5, height: 1.8, color: C.textSoft)),
                  ]),
                ),
                if (Progress.isFav(h.key)) Icon(Icons.bookmark_rounded, color: C.gold, size: 18),
              ]),
            ),
          );
        },
      ),
    );
  }
}

/// عرض الحديث: النص، الشرح، الاستماع، الحفظ، المشاركة، والتنقل بالسحب.
class HadithView extends StatefulWidget {
  final List<HadithItem> items;
  final int index;
  const HadithView({super.key, required this.items, required this.index});

  @override
  State<HadithView> createState() => _HadithViewState();
}

class _HadithViewState extends State<HadithView> {
  late final PageController _pc = PageController(initialPage: widget.index);
  late int _i = widget.index;
  bool _speaking = false;

  @override
  void dispose() {
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _listen(HadithItem h) async {
    if (_speaking) {
      await Voice.stop();
      setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    final base = 'assets/audio/hadith/${h.book}_${h.n}';
    await Voice.say(h.text, clip: base, force: true);
    if (mounted && _speaking && h.sharh != null) {
      await Voice.say('${h.title ?? ''}. ${h.sharh}', clip: '${base}_s', force: true);
    }
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.items[_i];
    final fav = Progress.isFav(h.key);
    return AppPage(
      title: 'الحديث ${ar(h.n)}',
      actions: [
        IconButton(
          tooltip: fav ? 'إزالة من المحفوظات' : 'حفظ',
          icon: Icon(fav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: C.gold),
          onPressed: () async {
            await Progress.toggleFav(h.key);
            HapticFeedback.selectionClick();
            setState(() {});
          },
        ),
      ],
      body: Column(children: [
        Expanded(
          child: PageView.builder(
            controller: _pc,
            reverse: false,
            itemCount: widget.items.length,
            onPageChanged: (i) {
              Voice.stop();
              setState(() {
                _i = i;
                _speaking = false;
              });
            },
            itemBuilder: (_, i) => _page(widget.items[i]),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(children: [
            Expanded(
              child: GoldButton(
                label: _speaking ? 'إيقاف' : 'استمع',
                icon: _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                onPressed: () => _listen(h),
              ),
            ),
            SizedBox(width: 10),
            _square(Icons.copy_rounded, 'نسخ', () {
              Clipboard.setData(ClipboardData(text: h.text));
              toast(context, 'تم نسخ الحديث');
            }),
            SizedBox(width: 10),
            _square(Icons.share_rounded, 'مشاركة', () {
              Share.share('${h.text}${h.sharh == null ? '' : '\n\nالفائدة: ${h.sharh}'}\n\n— من تطبيق المحفظ');
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _square(IconData i, String tip, VoidCallback onTap) => Pressable(
        onTap: onTap,
        child: Tooltip(
          message: tip,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line2)),
            child: Icon(i, color: C.text),
          ),
        ),
      );

  Widget _page(HadithItem h) {
    return ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
      if (h.title != null)
        Text(h.title!, textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: C.gold)).enter(0),
      SizedBox(height: 12),
      Panel(
        radius: 24,
        padding: EdgeInsets.all(20),
        child: Text(h.text, style: TextStyle(fontFamily: 'Amiri', fontSize: 21, height: 2.0)),
      ).enter(1),
      if (h.sharh != null) ...[
        SizedBox(height: 14),
        Panel(
          color: C.greenSoft,
          border: C.line2,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lightbulb_rounded, color: C.green),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الفائدة والشرح', style: TextStyle(color: C.green, fontWeight: FontWeight.w600)),
                SizedBox(height: 6),
                Text(h.sharh!, style: TextStyle(height: 1.9, fontSize: 15)),
              ]),
            ),
          ]),
        ).enter(2),
      ],
      SizedBox(height: 12),
      Text('اسحب يمينًا أو يسارًا للتنقل بين الأحاديث', textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 11.5)),
    ]);
  }
}

class HadithSearchScreen extends StatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  List<HadithItem> _res = [];
  List<(HadithItem, String)>? _index;

  void _search(String q) {
    _index ??= Hadiths.all().map((h) => (h, h.text.split(RegExp(r'\s+')).map(Matcher.normalize).join(' '))).toList();
    final n = q.trim().split(RegExp(r'\s+')).map(Matcher.normalize).where((w) => w.length > 1).toList();
    if (n.isEmpty) {
      setState(() => _res = []);
      return;
    }
    setState(() => _res = _index!.where((e) => n.every((w) => e.$2.contains(w))).map((e) => e.$1).take(100).toList());
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'البحث في الأحاديث',
      body: Column(children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: TextField(
            autofocus: true,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'اكتب كلمة مثل: النية، الصبر، الجار',
              prefixIcon: Icon(Icons.search_rounded),
              filled: true,
              fillColor: C.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _res.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Panel(
                onTap: () => _openHadith(context, _res, i),
                child: Text(_matn(_res[i].text), maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 16, height: 1.8)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Progress.favorites.map(Hadiths.byKey).whereType<HadithItem>().toList();
    if (items.isEmpty) {
      return AppPage(
        title: 'المحفوظات',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('لم تحفظ أحاديث بعد.\nاضغط علامة الحفظ أعلى أي حديث.', textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.8)),
          ),
        ),
      );
    }
    return HadithListScreen(title: 'المحفوظات', items: items);
  }
}
