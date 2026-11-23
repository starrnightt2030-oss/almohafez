import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../data/quran.dart';
import '../services/groups.dart';
import '../services/updater.dart';
import '../services/voice.dart';
import 'hifz_session.dart';
import 'test_screen.dart';

/// المجموعات: احفظ مع عائلتك وأصحابك بخطة ومدة، وتنافسوا في الخير.
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  List<Group>? _groups;
  bool _online = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!Groups.available) {
      setState(() => _groups = []);
      return;
    }
    final ok = await Groups.init();
    if (!ok) {
      if (mounted) setState(() => _online = false);
      return;
    }
    final out = <Group>[];
    for (final c in await Groups.myCodes()) {
      final g = await Groups.fetch(c);
      if (g != null) out.add(g);
    }
    if (mounted) setState(() => _groups = out);
  }

  Future<bool> _ensureName() async {
    if ((Progress.name ?? '').trim().isNotEmpty) return true;
    final c = TextEditingController();
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('اسمك في المجموعة'),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: 'مثلًا: أحمد')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text('حفظ'))],
      ),
    );
    if (v == null || v.trim().isEmpty) return false;
    await Progress.setName(v);
    return true;
  }

  Future<void> _create() async {
    if (!await _ensureName() || !mounted) return;
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CreateSheet(),
    );
    if (code == null || !mounted) return;
    await _load();
    final g = _groups?.where((x) => x.code == code).firstOrNull;
    if (g != null && mounted) {
      await go(context, GroupScreen(group: g));
      _load();
    }
  }

  Future<void> _join() async {
    if (!await _ensureName() || !mounted) return;
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('الانضمام لمجموعة'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.w700),
          decoration: InputDecoration(hintText: 'كود المجموعة'),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text('انضمام'))],
      ),
    );
    if (code == null || code.trim().length < 4 || !mounted) return;
    final g = await Groups.join(code);
    if (!mounted) return;
    if (g == null) {
      toast(context, 'الكود غير صحيح، تأكد منه وحاول مرة أخرى');
      return;
    }
    Voice.cue('group_welcome');
    await go(context, GroupScreen(group: g));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'المجموعات',
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        HeroHeader(
          title: 'احفظوا معًا',
          subtitle: '«وفي ذلك فليتنافس المتنافسون»\nخطة ومدة، ووِرد يومي، واختبار نهائي وترتيب',
          trailing: Icon(Icons.groups_rounded, size: 56),
        ).enter(0),
        SizedBox(height: 16),
        if (!Groups.available)
          Panel(
            child: Text('المجموعات قيد التجهيز وستعمل في التحديث القادم بإذن الله.', style: TextStyle(color: C.muted, height: 1.7)),
          )
        else if (!_online)
          Panel(child: Text('تعذّر الاتصال. المجموعات تحتاج إنترنت — تأكد من الاتصال وحاول مرة أخرى.', style: TextStyle(color: C.muted, height: 1.7)))
        else ...[
          Row(children: [
            Expanded(child: GoldButton(label: 'مجموعة جديدة', icon: Icons.add_rounded, onPressed: _create)),
            SizedBox(width: 10),
            Expanded(child: GoldButton(label: 'انضمام بكود', icon: Icons.login_rounded, outlined: true, onPressed: _join)),
          ]).enter(1),
          SizedBox(height: 18),
          if (_groups == null) Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_groups != null && _groups!.isEmpty)
            Panel(child: Text('لست في أي مجموعة بعد. أنشئ مجموعة وادعُ أهلك وأصحابك بالكود، أو انضم بكود وصلك.', style: TextStyle(color: C.muted, height: 1.7))),
          for (final g in _groups ?? <Group>[]) _tile(g),
        ],
      ]),
    );
  }

  Widget _tile(Group g) {
    final total = g.plan.ayahs.length;
    final mine = g.plan.ayahs.where(Progress.isMem).length;
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Panel(
        onTap: () async {
          await go(context, GroupScreen(group: g));
          _load();
        },
        child: Row(children: [
          ScoreRing(value: total == 0 ? 0 : mine / total, size: 54, label: '${ar((total == 0 ? 0 : mine * 100 / total).round())}٪'),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(g.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('${g.plan.title} · ${ar(g.memberCount)} أعضاء', style: TextStyle(fontSize: 12, color: C.muted)),
              Text(g.ended ? 'انتهت المدة — وقت الاختبار النهائي' : 'باقي ${ar(g.daysLeft)} يوم', style: TextStyle(fontSize: 12, color: g.ended ? C.coral : C.gold)),
            ]),
          ),
          Icon(Icons.chevron_left_rounded, color: C.muted),
        ]),
      ),
    );
  }
}

class _CreateSheet extends StatefulWidget {
  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _name = TextEditingController(text: 'حفظ العائلة');
  String _type = 'juz';
  int _juz = 30;
  int _surah = 67;
  int _days = 30;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('مجموعة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 12),
        TextField(controller: _name, maxLength: 40, decoration: InputDecoration(labelText: 'اسم المجموعة')),
        SizedBox(height: 4),
        SegmentedButton<String>(
          segments: [ButtonSegment(value: 'juz', label: Text('جزء')), ButtonSegment(value: 'surah', label: Text('سورة'))],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        SizedBox(height: 10),
        if (_type == 'juz')
          DropdownButtonFormField<int>(
            value: _juz,
            decoration: InputDecoration(labelText: 'الجزء'),
            items: [for (var j = 30; j >= 1; j--) DropdownMenuItem(value: j, child: Text('الجزء ${ar(j)}'))],
            onChanged: (v) => setState(() => _juz = v ?? 30),
          )
        else
          DropdownButtonFormField<int>(
            value: _surah,
            decoration: InputDecoration(labelText: 'السورة'),
            items: [
              for (final s in QuranData.surahs)
                DropdownMenuItem(value: s.number, child: Text('${ar(s.number)}. ${s.name} (${ar(s.count)} آية)')),
            ],
            onChanged: (v) => setState(() => _surah = v ?? 67),
          ),
        SizedBox(height: 10),
        DropdownButtonFormField<int>(
          value: _days,
          decoration: InputDecoration(labelText: 'المدة'),
          items: [for (final d in [7, 14, 30, 60, 90]) DropdownMenuItem(value: d, child: Text('${ar(d)} يومًا'))],
          onChanged: (v) => setState(() => _days = v ?? 30),
        ),
        SizedBox(height: 8),
        Builder(builder: (_) {
          final plan = _type == 'juz' ? GroupPlan('juz', _juz) : GroupPlan('surah', _surah);
          final n = plan.ayahs.length;
          return Text('${ar(n)} آية · حوالي ${ar((n / _days).ceil())} آيات يوميًا', style: TextStyle(color: C.muted, fontSize: 12.5));
        }),
        SizedBox(height: 14),
        GoldButton(
          label: _busy ? 'جارٍ الإنشاء…' : 'إنشاء المجموعة',
          onPressed: _busy
              ? null
              : () async {
                  if (_name.text.trim().isEmpty) return;
                  setState(() => _busy = true);
                  final plan = _type == 'juz' ? GroupPlan('juz', _juz) : GroupPlan('surah', _surah);
                  final code = await Groups.create(_name.text, plan, _days);
                  if (!mounted) return;
                  if (code == null) {
                    setState(() => _busy = false);
                    toast(context, 'تعذّر إنشاء المجموعة، تأكد من الإنترنت');
                    return;
                  }
                  Navigator.pop(context, code);
                },
        ),
      ]),
    );
  }
}

/// صفحة مجموعة: الكود والدعوة، وِردي اليوم، الترتيب، تمديد المدة، الاختبار النهائي.
class GroupScreen extends StatefulWidget {
  final Group group;
  const GroupScreen({super.key, required this.group});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  @override
  void initState() {
    super.initState();
    Groups.pushProgress(widget.group);
  }

  void _invite(Group g) {
    Share.share('انضم لمجموعتي «${g.name}» في تطبيق سَنَد لنحفظ ${g.plan.title} معًا خلال ${ar(g.totalDays)} يومًا.\n'
        'كود المجموعة: ${g.code}\n'
        '${kStore ? 'حمّل التطبيق من Google Play: https://play.google.com/store/apps/details?id=com.almohafez.almohafez' : 'حمّل التطبيق: https://github.com/${Updater.repo}/releases/latest'}');
  }

  Future<void> _continue(Group g) async {
    final next = g.plan.ayahs.where((r) => !Progress.isMem(r)).firstOrNull ?? g.plan.ayahs.first;
    await go(context, HifzSession(surah: next.s, startAyah: next.a));
    await Groups.pushProgress(g);
    if (mounted) setState(() {});
  }

  Future<void> _final(Group g) async {
    Voice.cue('group_final');
    await go(
        context,
        TestScreen.range('الاختبار النهائي: ${g.name}', g.plan.ayahs, questions: 8, onFinished: (pct) {
          Groups.submitFinal(g, pct);
        }));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Group?>(
      stream: Groups.watch(widget.group.code),
      initialData: widget.group,
      builder: (context, snap) {
        final g = snap.data ?? widget.group;
        final total = g.plan.ayahs.length;
        final mine = g.plan.ayahs.where(Progress.isMem).length;
        final behind = g.expectedNow - mine;
        final uid = Groups.uid;
        final voted = uid != null && g.votes.contains(uid);
        return AppPage(
          title: g.name,
          actions: [
            IconButton(
              tooltip: 'مغادرة المجموعة',
              icon: Icon(Icons.logout_rounded),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('مغادرة المجموعة؟'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('مغادرة')),
                    ],
                  ),
                );
                if (ok == true) {
                  await Groups.leave(g.code);
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
          ],
          body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
            HeroHeader(
              title: g.plan.title,
              subtitle: g.ended
                  ? 'انتهت المدة — حان وقت الاختبار النهائي'
                  : 'باقي ${ar(g.daysLeft)} يوم من ${ar(g.totalDays)} · ${ar(g.dailyTarget)} آيات يوميًا',
              trailing: ScoreRing(value: total == 0 ? 0 : mine / total, size: 82, label: '${ar(mine)}', sub: 'من ${ar(total)}'),
            ).enter(0),
            SizedBox(height: 12),
            Panel(
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('كود الدعوة', style: TextStyle(fontSize: 12, color: C.muted)),
                    Text(g.code, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 24, letterSpacing: 4, fontWeight: FontWeight.w700, color: C.gold)),
                  ]),
                ),
                IconButton(
                  tooltip: 'نسخ',
                  icon: Icon(Icons.copy_rounded, color: C.gold),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: g.code));
                    toast(context, 'تم نسخ الكود');
                  },
                ),
                SizedBox(width: 100, child: GoldButton(label: 'ادعُ', icon: Icons.share_rounded, height: 44, onPressed: () => _invite(g))),
              ]),
            ).enter(1),
            SizedBox(height: 12),
            if (!g.ended && mine < total)
              Panel(
                border: behind > 0 ? C.coral.withOpacity(0.5) : C.goldLine,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text(behind > 0 ? 'متأخر عن الخطة ${ar(behind)} آية — عوّضها اليوم' : 'أنت على الخطة، ما شاء الله',
                      style: TextStyle(fontWeight: FontWeight.w600, color: behind > 0 ? C.coral : C.green)),
                  SizedBox(height: 10),
                  GoldButton(label: 'احفظ وِرد المجموعة', icon: Icons.mic_rounded, onPressed: () => _continue(g)),
                ]),
              ).enter(2),
            if (g.ended || mine >= total) ...[
              GoldButton(label: 'الاختبار النهائي', icon: Icons.quiz_rounded, onPressed: () => _final(g)).enter(2),
            ],
            if (!g.ended) ...[
              SizedBox(height: 10),
              GoldButton(
                label: voted ? 'صوّتّ على التمديد (${ar(g.votes.length)}/${ar(g.memberCount)})' : 'اطلب تمديد المدة ٣ أيام (${ar(g.votes.length)}/${ar(g.memberCount)})',
                icon: Icons.more_time_rounded,
                outlined: true,
                onPressed: voted
                    ? null
                    : () async {
                        final extended = await Groups.voteExtend(g);
                        if (mounted) toast(context, extended ? 'تم تمديد المدة ٣ أيام' : 'تم تسجيل صوتك — التمديد يحتاج موافقة أكثر من نصف الأعضاء');
                      },
              ).enter(3),
            ],
            SizedBox(height: 18),
            SectionTitle('الترتيب'),
            StreamBuilder<List<Member>>(
              stream: Groups.members(g.code),
              builder: (context, ms) {
                final list = [...(ms.data ?? <Member>[])]..sort((a, b) => b.points(total).compareTo(a.points(total)));
                if (list.isEmpty) return Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                return Column(children: [for (var i = 0; i < list.length; i++) _member(i, list[i], total, list[i].uid == uid)]);
              },
            ),
            SizedBox(height: 8),
            Text('النقاط: الحفظ ٦٠٪ + الاختبار النهائي ٣٠٪ + الالتزام اليومي ١٠٪', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: C.muted)),
          ]),
        );
      },
    );
  }

  Widget _member(int i, Member m, int total, bool me) {
    final medal = i == 0 ? Color(0xFFE7C77B) : (i == 1 ? Color(0xFFC0C6CF) : (i == 2 ? Color(0xFFCD8B5A) : null));
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Panel(
        border: me ? C.goldLine : C.line,
        color: me ? C.goldSoft : null,
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: medal ?? C.surface2),
            child: Text(ar(i + 1), style: TextStyle(fontWeight: FontWeight.w700, color: medal != null ? Color(0xFF2A1E07) : C.muted)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(me ? '${m.name} (أنت)' : m.name, style: TextStyle(fontWeight: FontWeight.w600)),
              Text('${ar(m.done)}/${ar(total)} آية · 🔥 ${ar(m.streak)}${m.finalScore != null ? ' · الاختبار ${ar(m.finalScore!)}٪' : ''}',
                  style: TextStyle(fontSize: 11.5, color: C.muted)),
            ]),
          ),
          Text('${ar(m.points(total))}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.gold)),
          Text(' ن', style: TextStyle(fontSize: 11, color: C.muted)),
        ]),
      ),
    );
  }
}
