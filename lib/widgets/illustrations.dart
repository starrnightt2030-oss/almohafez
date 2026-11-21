import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// رسومات الواجهة (منقولة من تصميم Claude Design) — كلها مرسومة بالكود فتبقى حادة على أي شاشة.

/// رسم في مساحة ثابتة (w×h) يتكبّر على قد الويدجت.
abstract class _Fixed extends CustomPainter {
  final double w, h;
  _Fixed(this.w, this.h);
  void draw(Canvas c);
  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / w, size.height / h);
    canvas.save();
    canvas.translate((size.width - w * s) / 2, (size.height - h * s) / 2);
    canvas.scale(s);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// مصحف مفتوح على حامل خشب.
class QuranStandPainter extends _Fixed {
  final Color gold;
  QuranStandPainter({this.gold = const Color(0xFFC9A55A)}) : super(140, 110);
  @override
  void draw(Canvas c) {
    c.drawLine(Offset(32, 106), Offset(96, 46), _stroke(Color(0xFF7A4E24), 9));
    c.drawLine(Offset(108, 106), Offset(44, 46), _stroke(Color(0xFF94612F), 9));
    final base = Path()
      ..moveTo(70, 86)
      ..lineTo(14, 66)
      ..lineTo(14, 72)
      ..lineTo(70, 92)
      ..lineTo(126, 72)
      ..lineTo(126, 66)
      ..close();
    c.drawPath(base, _fill(Color(0xFF123C30)));
    c.drawPath(base, _stroke(gold, 1));
    final left = Path()
      ..moveTo(70, 58)
      ..lineTo(16, 38)
      ..quadraticBezierTo(11, 52, 16, 66)
      ..lineTo(70, 86)
      ..close();
    final right = Path()
      ..moveTo(70, 58)
      ..lineTo(124, 38)
      ..quadraticBezierTo(129, 52, 124, 66)
      ..lineTo(70, 86)
      ..close();
    c.drawPath(left, _fill(Color(0xFFF6ECD3)));
    c.drawPath(right, _fill(Color(0xFFFBF3DE)));
    c.drawLine(Offset(70, 58), Offset(70, 86), _stroke(gold, 1.2));
    final ln = _stroke(Color(0xCCB79A5A), 0.8);
    for (final y in [0.0, 6.0, 12.0]) {
      c.drawLine(Offset(26, 47 + y), Offset(62, 60 + y), ln);
      c.drawLine(Offset(78, 60 + y), Offset(114, 47 + y), ln);
    }
    c.drawCircle(Offset(96, 58), 5, _stroke(gold, 1));
  }
}

/// ميكروفون وموجات صوت.
class MicPainter extends _Fixed {
  final Color wave;
  MicPainter({this.wave = const Color(0xFF7FD1C4)}) : super(140, 110);
  @override
  void draw(Canvas c) {
    for (final (x1, x2, o) in [(28.0, 18.0, 0.6), (16.0, 2.0, 0.35)]) {
      final p = _stroke(wave.withOpacity(o), 3);
      c.drawPath(Path()..moveTo(x1, x1 == 28 ? 40 : 32)..quadraticBezierTo(x2, 56, x1, x1 == 28 ? 72 : 80), p);
      final rx1 = 140 - x1, rx2 = 140 - x2;
      c.drawPath(Path()..moveTo(rx1, x1 == 28 ? 40 : 32)..quadraticBezierTo(rx2, 56, rx1, x1 == 28 ? 72 : 80), p);
    }
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(54, 14, 32, 56), Radius.circular(16));
    c.drawRRect(body, _fill(Color(0xFFE7C77B)));
    c.drawRRect(body, _stroke(Color(0xFF8C6B2E), 1.5));
    final g = _stroke(Color(0x998C6B2E), 1);
    for (final y in [30.0, 38.0, 46.0, 54.0]) {
      c.drawLine(Offset(58, y), Offset(82, y), g);
    }
    final gold = _stroke(Color(0xFFC9A55A), 4);
    c.drawPath(Path()..moveTo(44, 56)..quadraticBezierTo(44, 86, 70, 86)..quadraticBezierTo(96, 86, 96, 56), gold);
    c.drawLine(Offset(70, 86), Offset(70, 100), gold);
    c.drawLine(Offset(54, 102), Offset(86, 102), gold);
  }
}

/// كتب مكدّسة بشريط علامة.
class BooksPainter extends _Fixed {
  BooksPainter() : super(140, 110);
  @override
  void draw(Canvas c) {
    const g = Color(0xFFE7C77B);
    void book(Rect r, Color col, double deg) {
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.rotate(deg * math.pi / 180);
      final rr = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: r.width, height: r.height), Radius.circular(3));
      c.drawRRect(rr, _fill(col));
      c.drawRRect(rr, _stroke(g, 1));
      c.drawRect(Rect.fromLTWH(-r.width / 2 + 8, -r.height / 2 + 4, r.width - 16, 2), _fill(g.withOpacity(0.7)));
      c.restore();
    }

    book(Rect.fromLTWH(20, 78, 100, 18), Color(0xFF5A2E18), 0);
    book(Rect.fromLTWH(28, 60, 90, 18), Color(0xFF164C3C), -3);
    book(Rect.fromLTWH(24, 42, 94, 18), Color(0xFF7A3E1C), 2);
    c.drawPath(
        Path()
          ..moveTo(60, 20)
          ..lineTo(80, 20)
          ..lineTo(80, 42)
          ..lineTo(70, 36)
          ..lineTo(60, 42)
          ..close(),
        _fill(g.withOpacity(0.9)));
  }
}

/// مشهد رأس الصفحة الرئيسية لكل ثيم (مسجد وهلال وفوانيس/زخارف).
class HomeScenePainter extends CustomPainter {
  final String theme;
  final double t; // للحركة الخفيفة (تأرجح الفوانيس)
  HomeScenePainter(this.theme, {this.t = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final clip = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, h - 34)
      ..quadraticBezierTo(w / 2, h + 26, 0, h - 34)
      ..close();
    canvas.save();
    canvas.clipPath(clip);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.heroA, C.heroB])
              .createShader(Offset.zero & size));
    // زخرفة نجوم ثمانية خفيفة
    StarPatternPainter(color: C.pattern, opacity: C.dark ? 0.08 : 0.14).paint(canvas, size);
    final accent = C.heroAccent;
    switch (theme) {
      case 'ramadan':
        final star = _fill(Colors.white.withOpacity(0.9));
        for (final p in [(0.1, 0.18), (0.31, 0.09), (0.54, 0.25), (0.9, 0.12), (0.77, 0.36), (0.2, 0.42), (0.44, 0.47)]) {
          canvas.drawCircle(Offset(w * p.$1, h * p.$2), 1.3, star);
        }
        _crescent(canvas, Offset(w * 0.82, h * 0.36), 30, accent);
        _lantern(canvas, Offset(w * 0.17, 0), 46, accent, math.sin(t * 2 * math.pi) * 0.07);
        _lantern(canvas, Offset(w * 0.34, 0), 26, Color.lerp(accent, Colors.orange, 0.3)!, math.sin(t * 2 * math.pi + 1.4) * 0.09, small: true);
        _skyline(canvas, size, Color(0xFF0A1230));
        break;
      case 'sand':
        _archWindow(canvas, Offset(w * 0.77, h * 0.86), 46, 92, accent, C.heroB);
        _crescent(canvas, Offset(w * 0.77, h * 0.5), 15, accent);
        canvas.drawPath(
            Path()
              ..moveTo(0, h * 0.92)
              ..quadraticBezierTo(w * 0.23, h * 0.74, w * 0.49, h * 0.85)
              ..quadraticBezierTo(w * 0.75, h * 0.95, w, h * 0.78)
              ..lineTo(w, h)
              ..lineTo(0, h)
              ..close(),
            _fill(C.heroB));
        break;
      case 'pearl':
        final ring = _stroke(accent.withOpacity(0.25), 1);
        for (final r in [120.0, 86.0, 52.0]) {
          canvas.drawCircle(Offset(w * 0.82, h * 0.2), r, ring);
        }
        _mosque(canvas, Offset(w * 0.77, h * 0.82), Color(0xFF0E1F3D));
        break;
      case 'noor':
        _crescent(canvas, Offset(w * 0.8, h * 0.55), 24, accent);
        _mosque(canvas, Offset(w * 0.3, h * 0.84), Colors.black.withOpacity(0.18));
        break;
      default: // emerald
        _crescent(canvas, Offset(w * 0.82, h * 0.34), 26, accent);
        _archOutline(canvas, Offset(w * 0.5, h), w * 0.62, h * 0.95, accent.withOpacity(0.35));
        _mosque(canvas, Offset(w * 0.24, h * 0.86), Colors.black.withOpacity(0.28));
    }
    canvas.restore();
  }

  void _crescent(Canvas c, Offset o, double r, Color col) {
    final outer = Path()..addOval(Rect.fromCircle(center: o, radius: r));
    final inner = Path()..addOval(Rect.fromCircle(center: o + Offset(r * 0.42, -r * 0.18), radius: r * 0.86));
    c.drawPath(Path.combine(PathOperation.difference, outer, inner), _fill(col));
  }

  void _lantern(Canvas c, Offset top, double len, Color col, double swing, {bool small = false}) {
    final s = small ? 0.75 : 1.0;
    c.save();
    c.translate(top.dx, top.dy);
    c.rotate(swing);
    c.drawLine(Offset.zero, Offset(0, len), _stroke(col, 1.2));
    c.translate(0, len);
    final body = Path()
      ..moveTo(-12 * s, 0)
      ..lineTo(12 * s, 0)
      ..lineTo(8 * s, 8 * s)
      ..lineTo(8 * s, 30 * s)
      ..lineTo(12 * s, 36 * s)
      ..lineTo(-12 * s, 36 * s)
      ..lineTo(-8 * s, 30 * s)
      ..lineTo(-8 * s, 8 * s)
      ..close();
    c.drawPath(body, _fill(col));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-6 * s, 10 * s, 12 * s, 18 * s), Radius.circular(3)), _fill(Color(0xFFFFE9A8)));
    c.drawCircle(Offset(0, 19 * s), 14 * s, _fill(Color(0x33FFE9A8)));
    c.restore();
  }

  void _skyline(Canvas c, Size size, Color col) {
    final w = size.width, h = size.height;
    final p = Path()..moveTo(0, h);
    p.lineTo(0, h - 60);
    p.lineTo(w * 0.1, h - 60);
    p.lineTo(w * 0.1, h - 80);
    p.arcToPoint(Offset(w * 0.26, h - 80), radius: Radius.circular(w * 0.08));
    p.lineTo(w * 0.26, h - 60);
    p.lineTo(w * 0.33, h - 60);
    p.lineTo(w * 0.33, h - 120);
    p.lineTo(w * 0.36, h - 134);
    p.lineTo(w * 0.39, h - 120);
    p.lineTo(w * 0.39, h - 60);
    p.lineTo(w * 0.46, h - 60);
    p.lineTo(w * 0.46, h - 90);
    p.arcToPoint(Offset(w * 0.69, h - 90), radius: Radius.circular(w * 0.115));
    p.lineTo(w * 0.69, h - 60);
    p.lineTo(w * 0.77, h - 60);
    p.lineTo(w * 0.77, h - 78);
    p.arcToPoint(Offset(w * 0.88, h - 78), radius: Radius.circular(w * 0.055));
    p.lineTo(w * 0.88, h - 60);
    p.lineTo(w, h - 60);
    p.lineTo(w, h);
    p.close();
    c.drawPath(p, _fill(col));
  }

  void _mosque(Canvas c, Offset base, Color col) {
    final p = Path();
    // قبة
    p.moveTo(base.dx - 46, base.dy);
    p.lineTo(base.dx - 46, base.dy - 30);
    p.cubicTo(base.dx - 46, base.dy - 66, base.dx - 14, base.dy - 78, base.dx, base.dy - 92);
    p.cubicTo(base.dx + 14, base.dy - 78, base.dx + 46, base.dy - 66, base.dx + 46, base.dy - 30);
    p.lineTo(base.dx + 46, base.dy);
    p.close();
    c.drawPath(p, _fill(col));
    // مئذنتان
    for (final dx in [-70.0, 70.0]) {
      c.drawRect(Rect.fromLTWH(base.dx + dx - 5, base.dy - 110, 10, 110), _fill(col));
      c.drawPath(
          Path()
            ..moveTo(base.dx + dx - 7, base.dy - 110)
            ..lineTo(base.dx + dx, base.dy - 126)
            ..lineTo(base.dx + dx + 7, base.dy - 110)
            ..close(),
          _fill(col));
    }
  }

  void _archWindow(Canvas c, Offset bottomCenter, double halfW, double h, Color gold, Color fill) {
    final x = bottomCenter.dx, y = bottomCenter.dy;
    final p = Path()
      ..moveTo(x - halfW, y)
      ..lineTo(x - halfW, y - h * 0.55)
      ..quadraticBezierTo(x - halfW, y - h * 0.9, x, y - h)
      ..quadraticBezierTo(x + halfW, y - h * 0.9, x + halfW, y - h * 0.55)
      ..lineTo(x + halfW, y)
      ..close();
    c.drawPath(p, _fill(fill));
    c.drawPath(p, _stroke(gold, 1.5));
  }

  void _archOutline(Canvas c, Offset bottomCenter, double width, double h, Color col) {
    final x = bottomCenter.dx, y = bottomCenter.dy, hw = width / 2;
    final p = Path()
      ..moveTo(x - hw, y)
      ..lineTo(x - hw, y - h * 0.55)
      ..quadraticBezierTo(x - hw, y - h * 0.92, x, y - h)
      ..quadraticBezierTo(x + hw, y - h * 0.92, x + hw, y - h * 0.55)
      ..lineTo(x + hw, y);
    c.drawPath(p, _stroke(col, 1.4));
  }

  @override
  bool shouldRepaint(covariant HomeScenePainter old) => old.t != t || old.theme != theme;
}

/// ألوان كروت الأقسام المرسومة حسب الثيم: (بداية التدرج، نهايته، لون العنوان، لون الوصف، لون الإطار)
(List<Color>, Color, Color, Color) featureColors(int i) {
  final id = C.t.id;
  const emerald = [
    ([Color(0xFF2B7A60), Color(0xFF174A3B)], Color(0xFFF2D68E), Color(0xFFE3D7B8), Color(0xFFC9A55A)),
    ([Color(0xFF1E5E66), Color(0xFF123C42)], Color(0xFFF2D68E), Color(0xFFDCE6E4), Color(0xFFC9A55A)),
    ([Color(0xFFA0803C), Color(0xFF5E4519)], Color(0xFFFFF0C9), Color(0xFFF6E7C4), Color(0xFFE7C77B)),
  ];
  const ramadan = [
    ([Color(0xFF2A3C86), Color(0xFF18245A)], Color(0xFFF4C95D), Color(0xFFD3DAF5), Color(0xFFF4C95D)),
    ([Color(0xFF1F4F7A), Color(0xFF142E4E)], Color(0xFFFFDD85), Color(0xFFCFE0F0), Color(0xFFF4C95D)),
    ([Color(0xFF5A3F8C), Color(0xFF2E2058)], Color(0xFFFFDD85), Color(0xFFE2D8F6), Color(0xFFF4C95D)),
  ];
  const sand = [
    ([Color(0xFF6B4A32), Color(0xFF3E2A1C)], Color(0xFFF4DFAE), Color(0xFFE8D6B4), Color(0xFFE8C77E)),
    ([Color(0xFF8C6A3E), Color(0xFF5A4022)], Color(0xFFFFF0C9), Color(0xFFF2E3C4), Color(0xFFE8C77E)),
    ([Color(0xFF4E6B4A), Color(0xFF2E4230)], Color(0xFFF4DFAE), Color(0xFFDCE6D4), Color(0xFFE8C77E)),
  ];
  const pearl = [
    ([Color(0xFF1E3F75), Color(0xFF12264A)], Color(0xFFE9CD86), Color(0xFFD6E0F3), Color(0xFFE9CD86)),
    ([Color(0xFF2F5FA8), Color(0xFF1B3D74)], Color(0xFFFFF3D2), Color(0xFFDDE7F8), Color(0xFFE9CD86)),
    ([Color(0xFFB08A3E), Color(0xFF7A5C22)], Color(0xFFFFF6DE), Color(0xFFF6EAD0), Color(0xFFF2DCA0)),
  ];
  const noor = [
    ([Color(0xFF1F6B4F), Color(0xFF174F3B)], Color(0xFFF3E3AE), Color(0xFFDDEBE3), Color(0xFFE9D9A6)),
    ([Color(0xFF2C6E78), Color(0xFF1C4A52)], Color(0xFFF3E3AE), Color(0xFFDCEBEE), Color(0xFFE9D9A6)),
    ([Color(0xFFA07A22), Color(0xFF6E5214)], Color(0xFFFFF3D2), Color(0xFFF6EAD0), Color(0xFFF3E3AE)),
  ];
  final set = switch (id) { 'ramadan' => ramadan, 'sand' => sand, 'pearl' => pearl, 'noor' => noor, _ => emerald };
  return set[i % 3];
}
