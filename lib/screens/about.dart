import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../services/updater.dart';
import '../widgets/update_dialog.dart';

/// عن التطبيق: الاسم ورقم الإصدار والمطوّر، والتحديث التلقائي، والمصادر.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'عن التطبيق',
      body: ListView(padding: EdgeInsets.fromLTRB(20, 4, 20, 28), children: [
        Center(
          child: Image.asset(kEmblem, width: 150, height: 150, filterQuality: FilterQuality.high),
        ).enter(0),
        SizedBox(height: 4),
        Center(child: Text('معلّمك الشخصي للقرآن الكريم', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: C.gold))).enter(1),
        SizedBox(height: 18),
        Panel(
          child: Column(children: [
            _row('التطبيق', '$kAppName · Sanad'),
            Divider(color: C.line, height: 22),
            _row('الإصدار', ar(Updater.current)),
            Divider(color: C.line, height: 22),
            _row('المطوّر', kDeveloper, ltr: true, accent: true),
          ]),
        ).enter(2),
        SizedBox(height: 12),
        Panel(
          onTap: () => checkForUpdates(context, manual: true),
          border: C.green.withOpacity(0.4),
          child: Row(children: [
            IconBox(icon: Icons.system_update_rounded, color: C.green, bg: C.greenSoft),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('التحديثات تلقائية', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('أول ما تنزل نسخة جديدة هتوصلك جوّه التطبيق', style: TextStyle(fontSize: 12, color: C.muted)),
              ]),
            ),
            Text('ابحث الآن', style: TextStyle(color: C.green, fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ).enter(3),
        SizedBox(height: 12),
        Panel(
          onTap: () => Share.share('تطبيق $kAppName — معلّمك الشخصي للقرآن الكريم: حفظ مع الشيخ وتصحيح فوري وأكاديمية تجويد ومكتبة إسلامية.\nhttps://github.com/${Updater.repo}/releases/latest'),
          child: Row(children: [
            IconBox(icon: Icons.share_rounded, color: C.gold, bg: C.goldSoft),
            SizedBox(width: 12),
            Expanded(child: Text('شارك التطبيق', style: TextStyle(fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_left_rounded, color: C.muted),
          ]),
        ).enter(4),
        SizedBox(height: 12),
        Panel(
          child: Text(
            'المصادر: نص المصحف برواية حفص (مشروع Tanzil ومجمع الملك فهد)، وبيانات أحكام التجويد (quran-tajweed)، '
            'والتفسير الميسّر (مجمع الملك فهد)، والتلاوات من EveryAyah، وكتب الأحاديث (الأربعون النووية، الأربعون القدسية، رياض الصالحين). '
            'الخطوط: Amiri وAmiri Quran وReadex Pro وAref Ruqaa برخصة SIL OFL.\n\n'
            'الشهادات في التطبيق تشجيعية، وليست إجازة بالسند.\n\n'
            'لا نجمع أي بيانات: كل تقدّمك محفوظ على جهازك فقط.',
            style: TextStyle(color: C.muted, height: 1.8, fontSize: 12.5),
          ),
        ).enter(5),
        SizedBox(height: 16),
        Center(child: Text('صدقة جارية · مجاني بالكامل وبلا إعلانات', style: TextStyle(fontSize: 12, color: C.muted))),
      ]),
    );
  }

  Widget _row(String k, String v, {bool ltr = false, bool accent = false}) => Row(children: [
        Text(k, style: TextStyle(color: C.muted, fontSize: 13)),
        Spacer(),
        Text(v,
            textDirection: ltr ? TextDirection.ltr : null,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: accent ? C.gold : C.text)),
      ]);
}
