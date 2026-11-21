import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HadithItem {
  final String book;
  final int section;
  final int n;
  final String? title;
  final String text;
  final String? sharh;
  HadithItem(this.book, this.section, this.n, this.title, this.text, this.sharh);
  String get key => '$book:$section:$n';
}

class HadithSection {
  final String title;
  final List<HadithItem> items;
  HadithSection(this.title, this.items);
}

class HadithBook {
  final String id;
  final String title;
  final String author;
  final String desc;
  final List<HadithSection> sections;
  HadithBook(this.id, this.title, this.author, this.desc, this.sections);
  int get count => sections.fold(0, (a, s) => a + s.items.length);
}

/// كتب الحديث المضمّنة: الأربعون النووية، الأربعون القدسية، رياض الصالحين.
class Hadiths {
  static final List<HadithBook> books = [];

  static Future<void> load() async {
    if (books.isNotEmpty) return;
    final j = jsonDecode(await rootBundle.loadString('assets/quran/hadith.json')) as Map<String, dynamic>;
    for (final b in (j['books'] as List)) {
      final m = b as Map<String, dynamic>;
      final id = m['id'] as String;
      final secs = <HadithSection>[];
      final rawSecs = m['sections'] as List;
      for (var si = 0; si < rawSecs.length; si++) {
        final s = rawSecs[si] as Map<String, dynamic>;
        secs.add(HadithSection(
          s['title'] as String,
          (s['items'] as List).map((e) {
            final h = e as Map<String, dynamic>;
            return HadithItem(id, si, h['n'] as int, h['t'] as String?, h['x'] as String, h['s'] as String?);
          }).toList(),
        ));
      }
      books.add(HadithBook(id, m['title'] as String, m['author'] as String, m['desc'] as String, secs));
    }
  }

  static HadithItem? byKey(String key) {
    final p = key.split(':');
    if (p.length != 3) return null;
    for (final b in books) {
      if (b.id != p[0]) continue;
      final si = int.tryParse(p[1]) ?? 0;
      if (si >= b.sections.length) return null;
      final n = int.tryParse(p[2]) ?? 0;
      for (final h in b.sections[si].items) {
        if (h.n == n) return h;
      }
    }
    return null;
  }

  static List<HadithItem> all() => [for (final b in books) for (final s in b.sections) ...s.items];

  /// حديث اليوم من الأربعين النووية والقدسية.
  static HadithItem today() {
    final pool = [for (final b in books.where((b) => b.id != 'riyad')) for (final s in b.sections) ...s.items];
    final day = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return pool[day % pool.length];
  }
}
