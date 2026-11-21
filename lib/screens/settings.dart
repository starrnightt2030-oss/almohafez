import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../services/voice.dart';
import '../services/updater.dart';
import '../widgets/update_dialog.dart';

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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => Voice.say('السلام عليكم ورحمة الله، هذا صوت التوجيه في تطبيق المحفظ', force: true),
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
        SectionTitle('عن التطبيق'),
        Panel(
          child: Row(children: [
            Icon(Icons.system_update_rounded, color: C.gold),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الإصدار ${Updater.current}', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('التحديثات بتوصلك تلقائيًا', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            TextButton(onPressed: () => checkForUpdates(context, manual: true), child: Text('البحث عن تحديث')),
          ]),
        ),
        SizedBox(height: 10),
        Panel(
          child: Text(
            'المحفظ تطبيق مجاني لتعلّم التجويد وحفظ القرآن الكريم والتفقه في الدين.\n\n'
            'المصادر: نص المصحف برواية حفص (مشروع Tanzil ومجمع الملك فهد)، وبيانات أحكام التجويد (quran-tajweed)، '
            'والتفسير الميسّر (مجمع الملك فهد)، والتلاوات من EveryAyah، وكتب الأحاديث (الأربعون النووية، الأربعون القدسية، رياض الصالحين). '
            'الخطوط: Amiri وAmiri Quran وReadex Pro برخصة SIL OFL.\n\n'
            'الشهادات في التطبيق تشجيعية، وليست إجازة بالسند.',
            style: TextStyle(color: C.muted, height: 1.8, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}
