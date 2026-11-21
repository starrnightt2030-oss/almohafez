import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../services/voice.dart';
import '../services/updater.dart';
import '../widgets/update_dialog.dart';
import 'about.dart';
import '../services/quran_ear.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _editName() async {
    final ctrl = TextEditingController(text: Progress.name ?? '');
    final v = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('اسمك'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text('حفظ')),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) {
      await Progress.setName(v);
      setState(() {});
    }
  }

  // اختيار صوت القراءة الآلية (للمقاطع اللي لسه ماتسجّلتش بصوت حقيقي)
  Future<void> _pickVoice() async {
    await Voice.init();
    final list = await Voice.arabicVoices();
    if (!mounted) return;
    if (list.isEmpty) {
      toast(context, 'مفيش أصوات عربي في محرّك الكلام على الموبايل. نزّل «خدمات الكلام من Google» واختار العربي.');
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: C.surface,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => ListView(
          shrinkWrap: true,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Text('اختار الصوت اللي يعجبك — اضغط على أي صوت تسمعه', style: TextStyle(color: C.muted, fontSize: 13)),
            SizedBox(height: 8),
            for (var k = 0; k < list.length; k++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Voice.current == list[k]['name'] ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: Voice.current == list[k]['name'] ? C.gold : C.muted),
                title: Text('صوت ${k + 1}  •  ${list[k]['locale']}'),
                subtitle: Text(list[k]['name'] ?? '', style: TextStyle(fontSize: 11, color: C.muted)),
                onTap: () async {
                  await Progress.setTtsVoice(list[k]['name']!);
                  await Voice.applyVoice(list[k]['name']);
                  setS(() {});
                  if (mounted) setState(() {});
                  await Voice.say('أهلًا بيك في سَنَد، ده صوت التوجيه', force: true);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _themeCard(int i) {
    final t = appThemes[i];
    final on = C.t.id == t.id;
    return Pressable(
      onTap: () => Progress.setTheme(i),
      child: Container(
        width: 118,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? C.gold : C.line, width: on ? 2.5 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [t.heroA, t.heroB]),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.auto_awesome_rounded, color: t.heroAccent, size: 20),
          ),
          SizedBox(height: 6),
          Row(children: [
            Expanded(child: Container(height: 22, decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(7), border: Border.all(color: t.line)))),
            SizedBox(width: 5),
            Container(width: 22, height: 22, decoration: BoxDecoration(color: t.gold, borderRadius: BorderRadius.circular(7))),
          ]),
          Spacer(),
          Text(t.name, textAlign: TextAlign.center, style: TextStyle(color: t.text, fontWeight: FontWeight.w700, fontSize: 13)),
          if (on) Icon(Icons.check_circle_rounded, color: t.gold, size: 16),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'الإعدادات',
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        Panel(
          onTap: _editName,
          child: Row(children: [
            IconBox(icon: Icons.person_rounded, color: C.gold, bg: C.goldSoft),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الاسم', style: TextStyle(color: C.muted, fontSize: 12)),
                Text(Progress.name ?? 'اضغط لإضافة اسمك', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              ]),
            ),
            Icon(Icons.edit_rounded, color: C.muted, size: 20),
          ]),
        ),
        SizedBox(height: 18),
        SectionTitle('ثيم التطبيق'),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: appThemes.length,
            separatorBuilder: (_, __) => SizedBox(width: 10),
            itemBuilder: (_, i) => _themeCard(i),
          ),
        ),
        SizedBox(height: 18),
        SectionTitle('الصوت والتوجيه'),
        Panel(
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: Progress.voiceOn,
              onChanged: (v) async {
                await Progress.setVoiceOn(v);
                setState(() {});
              },
              title: Text('الصوت الموجّه'),
              subtitle: Text('يقرأ الأسئلة ويوجهك عند الأخطاء والإجابات', style: TextStyle(fontSize: 12, color: C.muted)),
            ),
            Divider(color: C.line),
            Row(children: [
              Text('سرعة القراءة الصوتية', style: TextStyle(fontSize: 14)),
              Expanded(
                child: Slider(
                  value: Progress.voiceRate,
                  min: 0.3,
                  max: 0.7,
                  divisions: 8,
                  onChanged: (v) async {
                    await Progress.setVoiceRate(v);
                    setState(() {});
                  },
                ),
              ),
            ]),
            Divider(color: C.line),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.record_voice_over_rounded, color: C.gold),
              title: Text('صوت القراءة الآلية'),
              subtitle: Text(Voice.current ?? 'تلقائي (رجالي أولًا)', style: TextStyle(fontSize: 12, color: C.muted)),
              trailing: Icon(Icons.chevron_left_rounded),
              onTap: _pickVoice,
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Voice.say('السلام عليكم ورحمة الله، هذا صوت التوجيه في تطبيق سَنَد', force: true),
                icon: Icon(Icons.volume_up_rounded),
                label: Text('تجربة الصوت'),
              ),
            ),
          ]),
        ),
        SizedBox(height: 18),
        SectionTitle('المصحف'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: Progress.tajweedColors,
              onChanged: (v) async {
                await Progress.setTajweedColors(v);
                setState(() {});
              },
              title: Text('ألوان أحكام التجويد'),
            ),
            Divider(color: C.line),
            Text('القارئ الافتراضي', style: TextStyle(color: C.muted, fontSize: 12.5)),
            SizedBox(height: 6),
            for (final r in reciters)
              RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                value: r.id,
                groupValue: Progress.reciter,
                onChanged: (v) async {
                  if (v == null) return;
                  await Progress.setReciter(v);
                  setState(() {});
                },
                title: Text(r.name, style: TextStyle(fontSize: 14.5)),
                subtitle: Text(r.note, style: TextStyle(fontSize: 11.5, color: C.muted)),
              ),
          ]),
        ),
        SizedBox(height: 18),
        SectionTitle('المصحِّح الذكي'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(
              'يسمع تلاوتك على الموبايل نفسه بدون إنترنت، ويقارنها بالآية حرفًا حرفًا، ويفتح الميكروفون وحده بعد الشيخ ويقفله وحده عند آخر الآية.',
              style: TextStyle(fontSize: 12.5, color: C.muted, height: 1.7),
            ),
            SizedBox(height: 10),
            ValueListenableBuilder<double?>(
              valueListenable: QuranEar.progress,
              builder: (_, p, __) {
                if (p != null) {
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Text('جاري التحميل… ${ar((p * 100).round())}٪', style: TextStyle(fontSize: 13)),
                    SizedBox(height: 6),
                    ProgressBar(value: p),
                  ]);
                }
                return FutureBuilder<bool>(
                  future: QuranEar.checkInstalled(),
                  builder: (_, snap) {
                    final ok = snap.data ?? false;
                    return Row(children: [
                      Icon(ok ? Icons.check_circle_rounded : Icons.download_rounded, color: ok ? C.green : C.gold, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(ok ? 'جاهز ويعمل بدون إنترنت' : 'غير محمّل بعد (${ar((QuranEar.totalBytes / 1048576).round())} م.ب، مرة واحدة)',
                              style: TextStyle(fontSize: 13))),
                      if (!ok)
                        TextButton(
                          onPressed: () async {
                            final done = await QuranEar.download();
                            if (!mounted) return;
                            setState(() {});
                            toast(context, done ? 'المصحِّح الذكي جاهز' : 'تعذّر التحميل، تأكد من الإنترنت وحاول مرة أخرى');
                          },
                          child: Text('تحميل'),
                        ),
                    ]);
                  },
                );
              },
            ),
            Divider(color: C.line),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: Progress.smartEar,
              onChanged: (v) async {
                await Progress.setSmartEar(v);
                setState(() {});
              },
              title: Text('استخدام المصحِّح الذكي في الحفظ'),
              subtitle: Text('لو أوقفته يُستخدم التعرف على الصوت من Google', style: TextStyle(fontSize: 11.5, color: C.muted)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: Progress.strictRecite,
              onChanged: (v) async {
                await Progress.setStrictRecite(v);
                setState(() {});
              },
              title: Text('تصحيح صارم'),
              subtitle: Text('أي حرف مختلف يُحسب خطأ حتى في الكلمات الطويلة', style: TextStyle(fontSize: 11.5, color: C.muted)),
            ),
          ]),
        ),
        SizedBox(height: 18),
        SectionTitle('عن التطبيق'),
        Panel(
          onTap: () => go(context, AboutScreen()),
          child: Row(children: [
            Image.asset(kEmblem, width: 46, height: 46),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$kAppName · الإصدار ${ar(Updater.current)}', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('المطوّر $kDeveloper · التحديثات تلقائية', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Icon(Icons.chevron_left_rounded, color: C.muted),
          ]),
        ),
        SizedBox(height: 10),
        GoldButton(label: 'البحث عن تحديث', icon: Icons.system_update_rounded, outlined: true, onPressed: () => checkForUpdates(context, manual: true)),
      ]),
    );
  }
}
