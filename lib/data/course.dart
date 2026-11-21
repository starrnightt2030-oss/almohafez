import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'quran.dart';

class Example {
  final String text;
  final String note;
  final AyahRef? ref;
  Example(this.text, this.note, this.ref);
}

class Question {
  final String q;
  final List<String> options;
  final int answer;
  final String why;
  Question(this.q, this.options, this.answer, this.why);

  static Question fromJson(Map<String, dynamic> j) =>
      Question(j['q'] as String, (j['o'] as List).cast<String>(), j['a'] as int, j['why'] as String);
}

class Lesson {
  final String id;
  final String title;
  final List<String> paras;
  final List<Example> examples;
  final List<Question> quiz;
  Lesson(this.id, this.title, this.paras, this.examples, this.quiz);

  static Lesson fromJson(Map<String, dynamic> j) => Lesson(
        j['id'] as String,
        j['title'] as String,
        (j['paras'] as List).cast<String>(),
        (j['examples'] as List).map((e) {
          final m = e as Map<String, dynamic>;
          final r = m['ref'] as List?;
          return Example(m['text'] as String, m['note'] as String, r == null ? null : AyahRef(r[0] as int, r[1] as int));
        }).toList(),
        (j['quiz'] as List).map((e) => Question.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

/// باب في التجويد أو قسم في المكتبة.
class Unit {
  final String id;
  final String title;
  final String sub;
  final String icon;
  final String color;
  final List<Lesson> lessons;
  final List<String> drill;
  final List<AyahRef> practice;
  Unit(this.id, this.title, this.sub, this.icon, this.color, this.lessons, this.drill, this.practice);

  static Unit fromJson(Map<String, dynamic> j) => Unit(
        j['id'] as String,
        j['title'] as String,
        j['sub'] as String,
        j['icon'] as String,
        (j['color'] as String?) ?? 'gold',
        (j['lessons'] as List).map((e) => Lesson.fromJson(e as Map<String, dynamic>)).toList(),
        ((j['drill'] as List?) ?? []).cast<String>(),
        ((j['practice'] as List?) ?? []).map((e) => AyahRef((e as List)[0] as int, e[1] as int)).toList(),
      );
}

IconData unitIcon(String name) {
  switch (name) {
    case 'school':
      return Icons.school_rounded;
    case 'shield':
      return Icons.shield_rounded;
    case 'record_voice_over':
      return Icons.record_voice_over_rounded;
    case 'tune':
      return Icons.tune_rounded;
    case 'grain':
      return Icons.grain_rounded;
    case 'circle':
      return Icons.adjust_rounded;
    case 'translate':
      return Icons.translate_rounded;
    case 'contrast':
      return Icons.contrast_rounded;
    case 'graphic_eq':
      return Icons.graphic_eq_rounded;
    case 'straighten':
      return Icons.straighten_rounded;
    case 'join':
      return Icons.link_rounded;
    case 'text_fields':
      return Icons.text_fields_rounded;
    case 'pause':
      return Icons.pause_circle_outline_rounded;
    case 'verified':
      return Icons.verified_rounded;
    case 'water_drop':
      return Icons.water_drop_rounded;
    case 'mosque':
      return Icons.mosque_rounded;
    case 'nightlight':
      return Icons.nightlight_round;
    case 'volunteer_activism':
      return Icons.volunteer_activism_rounded;
    case 'location_on':
      return Icons.location_on_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'auto_awesome':
      return Icons.auto_awesome_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}

class Courses {
  static final List<Unit> tajweed = [];
  static final List<Unit> library = [];

  static Future<void> load() async {
    if (tajweed.isNotEmpty) return;
    final t = jsonDecode(await rootBundle.loadString('assets/quran/tajweed_course.json')) as Map<String, dynamic>;
    tajweed.addAll((t['chapters'] as List).map((e) => Unit.fromJson(e as Map<String, dynamic>)));
    final l = jsonDecode(await rootBundle.loadString('assets/quran/library.json')) as Map<String, dynamic>;
    library.addAll((l['categories'] as List).map((e) => Unit.fromJson(e as Map<String, dynamic>)));
  }

  static int get tajweedLessons => tajweed.fold(0, (a, u) => a + u.lessons.length);
}
