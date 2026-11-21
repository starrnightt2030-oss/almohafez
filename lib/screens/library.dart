import 'package:flutter/material.dart';
import '../theme.dart';

class Hadith {
  final String text;
  final String source;
  final String grade;
  final String meaning;
  final bool qudsi;
  const Hadith(this.text, this.source, this.grade, this.meaning, {this.qudsi = false});
}

/// مجموعة أولى من الأحاديث الصحيحة المشهورة، مع شرح ميسّر.
const hadiths = <Hadith>[
  Hadith('«إنّما الأعمالُ بالنيّات، وإنّما لكلّ امرئٍ ما نوى»', 'رواه البخاري ومسلم', 'متفق عليه',
      'النية أساس قبول العمل. فصحّح نيتك قبل كل عبادة وعمل، واجعله خالصًا لله.'),
  Hadith('«خيرُكم مَن تعلّم القرآنَ وعلّمه»', 'رواه البخاري', 'صحيح',
      'أفضل الناس من اشتغل بالقرآن تعلّمًا وتعليمًا، فاحرص على أن تكون منهم.'),
  Hadith('«لا يؤمنُ أحدُكم حتى يحبَّ لأخيه ما يحبُّ لنفسه»', 'رواه البخاري ومسلم', 'متفق عليه',
      'كمال الإيمان أن تتمنى لإخوانك من الخير ما تتمناه لنفسك.'),
  Hadith('«مَن كان يؤمنُ بالله واليوم الآخر فليقلْ خيرًا أو ليصمتْ»', 'رواه البخاري ومسلم', 'متفق عليه',
      'احفظ لسانك؛ فلا تتكلم إلا بخير، وإلا فالسكوت أسلم.'),
  Hadith('«الدِّينُ النصيحة»', 'رواه مسلم', 'صحيح',
      'الدين قائم على الإخلاص والصدق في النصح لله ولكتابه ولرسوله ولأئمة المسلمين وعامتهم.'),
  Hadith('«لا تغضبْ»', 'رواه البخاري', 'صحيح',
      'وصية جامعة: اجتنب أسباب الغضب، وإذا غضبت فلا تعمل بمقتضاه.'),
  Hadith('«مِن حُسنِ إسلامِ المرءِ تركُه ما لا يعنيه»', 'رواه الترمذي', 'حسن',
      'من علامات قوة الإسلام أن يترك المسلم ما لا يفيده في دينه ودنياه من قول أو فعل.'),
  Hadith('«يا عبادي، إنّي حرّمتُ الظلمَ على نفسي، وجعلتُه بينكم محرّمًا، فلا تظالموا»', 'رواه مسلم', 'صحيح',
      'الله تعالى نزّه نفسه عن الظلم، وحرّمه على عباده فيما بينهم.',
      qudsi: true),
  Hadith('«أنا عند ظنِّ عبدي بي، وأنا معه إذا ذكرني»', 'رواه البخاري ومسلم', 'متفق عليه',
      'أحسن الظن بالله وأكثر من ذكره؛ فالله مع الذاكرين بعونه وتوفيقه.',
      qudsi: true),
  Hadith('«قال الله: أَنفِقْ يا ابنَ آدم أُنفِقْ عليك»', 'رواه البخاري ومسلم', 'متفق عليه',
      'الإنفاق في سبيل الله سبب لزيادة الرزق والبركة فيه.',
      qudsi: true),
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final list = hadiths.where((h) => _tab == 0 || (_tab == 1 && !h.qudsi) || (_tab == 2 && h.qudsi)).toList();
    final today = hadiths[DateTime.now().day % hadiths.length];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      const Text('التفقّه في الدين', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 14),
      _hadithCard(today, featured: true),
      const SizedBox(height: 16),
      Row(children: [
        for (final t in const ['الكل', 'الحديث النبوي', 'القدسية'])
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(t),
              selected: _tab == ['الكل', 'الحديث النبوي', 'القدسية'].indexOf(t),
              onSelected: (_) => setState(() => _tab = ['الكل', 'الحديث النبوي', 'القدسية'].indexOf(t)),
              selectedColor: C.gold,
              backgroundColor: C.surface,
              labelStyle: TextStyle(
                  color: _tab == ['الكل', 'الحديث النبوي', 'القدسية'].indexOf(t) ? C.onGold : C.text, fontSize: 13),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      for (final h in list) Padding(padding: const EdgeInsets.only(bottom: 10), child: _hadithCard(h)),
      const SizedBox(height: 10),
      Panel(
        color: C.deep,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Row(children: [
            IconBox(icon: Icons.headphones_outlined, color: C.blue, bg: C.blueSoft),
            SizedBox(width: 12),
            Expanded(child: Text('دورات الفقه الميسّر — قريبًا', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
          ]),
          SizedBox(height: 10),
          Text('دروس صوتية مبسطة مع اختبارات: الطهارة، الصلاة، الصيام، الزكاة، الحج، وآداب المسلم.',
              style: TextStyle(color: C.muted, height: 1.7, fontSize: 13)),
        ]),
      ),
    ]);
  }

  Widget _hadithCard(Hadith h, {bool featured = false}) {
    return Panel(
      border: featured ? const Color(0xFF5C4B22) : C.line,
      radius: featured ? 24 : 20,
      padding: EdgeInsets.all(featured ? 18 : 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(featured ? 'حديث اليوم' : (h.qudsi ? 'حديث قدسي' : 'حديث نبوي'),
              style: TextStyle(fontSize: 12.5, color: h.qudsi ? C.purple : C.gold, fontWeight: FontWeight.w500)),
          const Spacer(),
          Tag(h.grade, fg: C.green, bg: C.greenSoft),
        ]),
        const SizedBox(height: 10),
        Text(h.text, style: TextStyle(fontFamily: 'Amiri', fontSize: featured ? 22 : 19, height: 1.8)),
        const SizedBox(height: 6),
        Text(h.source, style: const TextStyle(fontSize: 12, color: C.muted)),
        const SizedBox(height: 8),
        Text(h.meaning, style: const TextStyle(fontSize: 13.5, color: Color(0xFFC9D6D0), height: 1.8)),
      ]),
    );
  }
}
