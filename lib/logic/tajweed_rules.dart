import 'package:flutter/material.dart';

class TRule {
  final String key;
  final String name;
  final String desc;
  final Color color;
  const TRule(this.key, this.name, this.desc, this.color);
}

/// ترتيب الأحكام مطابق لملف tajweed.json.
const tRules = <TRule>[
  TRule('hamzat_wasl', 'همزة وصل', 'تُنطق عند الابتداء وتسقط عند الوصل.', Color(0xFF8A9C95)),
  TRule('silent', 'حرف لا يُنطق', 'حرف مكتوب لا يُقرأ وصلًا ولا وقفًا.', Color(0xFF8A9C95)),
  TRule('lam_shamsiyyah', 'لام شمسية', 'لام «ال» تُدغم في الحرف الشمسي بعدها فلا تُنطق.', Color(0xFF8A9C95)),
  TRule('madd_2', 'مد طبيعي', 'يُمد حركتين.', Color(0xFFE9C77E)),
  TRule('madd_246', 'مد عارض أو لين', 'يجوز مده ٢ أو ٤ أو ٦ حركات عند الوقف.', Color(0xFFF2A65A)),
  TRule('madd_muttasil', 'مد متصل', 'حرف مد بعده همز في كلمة: ٤ أو ٥ حركات.', Color(0xFFFF8F6B)),
  TRule('madd_munfasil', 'مد منفصل', 'حرف مد آخر كلمة وهمز أول التالية: ٤ أو ٥ حركات.', Color(0xFFFF8F6B)),
  TRule('madd_6', 'مد لازم', 'يُمد ست حركات وجوبًا.', Color(0xFFF26FB0)),
  TRule('ghunnah', 'غنة', 'نون أو ميم مشددة: غنة بمقدار حركتين.', Color(0xFF6FD68F)),
  TRule('qalqalah', 'قلقلة', 'نبرة قوية عند سكون حروف «قطب جد».', Color(0xFF4DD0E1)),
  TRule('ikhfa', 'إخفاء', 'إخفاء النون الساكنة أو التنوين مع غنة حركتين.', Color(0xFF58C9B9)),
  TRule('ikhfa_shafawi', 'إخفاء شفوي', 'إخفاء الميم الساكنة عند الباء مع غنة.', Color(0xFF58C9B9)),
  TRule('idghaam_ghunnah', 'إدغام بغنة', 'إدغام النون الساكنة أو التنوين في «ينمو» مع غنة.', Color(0xFF7FA8FF)),
  TRule('idghaam_no_ghunnah', 'إدغام بغير غنة', 'إدغام النون الساكنة أو التنوين في اللام والراء.', Color(0xFFA99BFF)),
  TRule('idghaam_shafawi', 'إدغام شفوي', 'إدغام الميم الساكنة في الميم مع غنة.', Color(0xFF7FA8FF)),
  TRule('idghaam_mutajanisayn', 'إدغام متجانسين', 'إدغام حرفين اتحدا مخرجًا واختلفا صفة.', Color(0xFFA99BFF)),
  TRule('idghaam_mutaqaribayn', 'إدغام متقاربين', 'إدغام حرفين متقاربين مخرجًا وصفة.', Color(0xFFA99BFF)),
  TRule('iqlab', 'إقلاب', 'قلب النون الساكنة أو التنوين ميمًا مخفاة عند الباء.', Color(0xFF9CCC65)),
];

int ruleIndex(String key) => tRules.indexWhere((r) => r.key == key);

/// أحكام تظهر في دليل الألوان (بدون تكرار الألوان).
const legendRules = ['madd_2', 'madd_246', 'madd_muttasil', 'madd_6', 'ghunnah', 'ikhfa', 'idghaam_ghunnah', 'idghaam_no_ghunnah', 'iqlab', 'qalqalah', 'hamzat_wasl'];
