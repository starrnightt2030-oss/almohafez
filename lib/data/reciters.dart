class Reciter {
  final String id;
  final String name;
  final String note;
  const Reciter(this.id, this.name, this.note);
}

/// التلاوات من EveryAyah (ملف لكل آية) — مجانية وتُشغّل عبر الإنترنت.
const reciters = <Reciter>[
  Reciter('Husary_Muallim_128kbps', 'محمود خليل الحصري', 'المصحف المعلّم — الأنسب للحفظ'),
  Reciter('Husary_128kbps', 'محمود خليل الحصري', 'مرتّل'),
  Reciter('Minshawy_Murattal_128kbps', 'محمد صديق المنشاوي', 'مرتّل'),
  Reciter('Abdul_Basit_Murattal_192kbps', 'عبد الباسط عبد الصمد', 'مرتّل'),
  Reciter('Alafasy_128kbps', 'مشاري راشد العفاسي', 'مرتّل'),
  Reciter('Abdullah_Basfar_192kbps', 'عبد الله بصفر', 'مرتّل'),
];

Reciter reciterById(String id) => reciters.firstWhere((r) => r.id == id, orElse: () => reciters.first);
