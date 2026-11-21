import 'package:flutter/material.dart';
import '../theme.dart';

/// المجموعات والتحديات — تحتاج خادم مزامنة مجاني (المرحلة الثالثة).
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      [Icons.group_add_outlined, 'أنشئ مجموعة', 'للأصدقاء أو العائلة، والدعوة برابط واحد على واتساب'],
      [Icons.flag_outlined, 'حدد التحدي', 'سورة أو جزء أو مستوى تجويد، ومدة يقسّمها التطبيق لوِرد يومي'],
      [Icons.timer_outlined, 'التمديد بالتصويت', 'لو المدة ما كفتش، الأعضاء يصوتوا على التمديد'],
      [Icons.favorite_border, 'شجّعوا بعض', 'تذكير يومي وأزرار تشجيع ودعاء'],
      [Icons.emoji_events_outlined, 'الاختبار والترتيب', 'اختبار نهائي عادل، وترتيب بالحفظ والتجويد والالتزام'],
    ];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
      const Text('المجموعات والتحديات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('«وفي ذلك فليتنافس المتنافسون»', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, color: C.gold)),
      const SizedBox(height: 16),
      Panel(
        border: C.line2,
        radius: 24,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Tag('قريبًا في التحديث القادم', fg: Color(0xFFF3D58F), bg: C.goldSoft),
          const SizedBox(height: 12),
          const Text('احفظ مع عائلتك وأصدقائك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                IconBox(icon: it[0] as IconData, color: C.coral, bg: C.coralSoft, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it[1] as String, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(it[2] as String, style: const TextStyle(fontSize: 12.5, color: C.muted, height: 1.6)),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
    ]);
  }
}
