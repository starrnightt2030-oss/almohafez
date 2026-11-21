import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/progress.dart';
import '../theme.dart';

const _cream1 = Color(0xFFFCF8EF);
const _cream2 = Color(0xFFF3EAD7);
const _gold = Color(0xFFC59B4A);
const _goldDeep = Color(0xFF9C7A35);
const _green = Color(0xFF1F4D3A);
const _greenDeep = Color(0xFF15382A);
const _ink = Color(0xFF3B3A33);

/// تصميم الشهادة الأفقي المزخرف (نمطان).
class CertificateArt extends StatelessWidget {
  final Cert cert;
  /// 0 = كلاسيكي بأشرطة ركنية وختم، 1 = بقوس جانبي
  final int style;
  const CertificateArt({super.key, required this.cert, this.style = 0});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1000 / 700,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 1000,
          height: 700,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [_cream1, _cream2], radius: 1.1),
                  ),
                ),
              ),
              Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: _gold, opacity: 0.06))),
              Positioned.fill(child: CustomPaint(painter: _FramePainter(bands: style == 0))),
              if (style == 0) ..._classic() else ..._arch(),
            ]),
          ),
        ),
      ),
    );
  }

  String get _achievement {
    switch (cert.kind) {
      case 'surah':
        return 'حفظ وتسميع ${cert.title}';
      case 'tajweed':
        return 'باب «${cert.title}» في أكاديمية التجويد';
      default:
        return 'دراسة واختبار «${cert.title}»';
    }
  }

  String get _reason {
    switch (cert.kind) {
      case 'surah':
        return 'وذلك بمناسبة إتمامه';
      case 'tajweed':
        return 'وذلك لاجتيازه بنجاح';
      default:
        return 'وذلك لإتمامه بنجاح';
    }
  }

  List<Widget> _classic() => [
        // الختم
        Positioned(left: 70, bottom: 120, child: _Seal()),
        Positioned(
          left: 210,
          right: 110,
          top: 50,
          bottom: 40,
          child: Column(children: [
            Text('شهادة تقدير', style: TextStyle(fontFamily: 'Ruqaa', fontSize: 76, fontWeight: FontWeight.w700, color: _green, height: 1.2)),
            _ornLine(),
            SizedBox(height: 6),
            Text('يتقدّم تطبيق سَنَد بخالص التقدير والتهنئة', style: TextStyle(fontFamily: 'Amiri', fontSize: 24, color: _ink)),
            SizedBox(height: 6),
            Text('إلى', style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: _ink)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _diamond(),
              SizedBox(width: 18),
              Flexible(
                child: Text(cert.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 54, fontWeight: FontWeight.w700, color: _green, height: 1.3)),
              ),
              SizedBox(width: 18),
              _diamond(),
            ]),
            Container(width: 420, height: 1.5, color: _gold),
            SizedBox(height: 10),
            Text(_reason, style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: _ink)),
            SizedBox(height: 8),
            _Banner(text: _achievement, width: 600),
            SizedBox(height: 12),
            _stats(),
            SizedBox(height: 12),
            Text('سائلين الله تعالى أن يجعله من أهل القرآن الذين هم أهل الله وخاصته،\nوأن ينفعه بما تعلّم، ويزيده من فضله وتوفيقه.',
                textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 19, color: _ink, height: 1.6)),
            Spacer(),
            _footer(),
          ]),
        ),
      ];

  List<Widget> _arch() => [
        Positioned(left: 50, top: 70, bottom: 70, width: 190, child: _ArchPanel()),
        Positioned(
          left: 270,
          right: 70,
          top: 50,
          bottom: 40,
          child: Column(children: [
            Text('شهادة شكر وتقدير', style: TextStyle(fontFamily: 'Ruqaa', fontSize: 70, fontWeight: FontWeight.w700, color: _green, height: 1.2)),
            _ornLine(),
            SizedBox(height: 8),
            Text('يتقدّم تطبيق سَنَد بخالص الشكر والتقدير إلى:', style: TextStyle(fontFamily: 'Amiri', fontSize: 23, color: _ink)),
            SizedBox(height: 10),
            Container(
              width: 560,
              height: 74,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color(0x66FFFFFF),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: _gold, width: 2),
              ),
              child: Text(cert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 44, fontWeight: FontWeight.w700, color: _green)),
            ),
            SizedBox(height: 12),
            Text(_reason, style: TextStyle(fontFamily: 'Amiri', fontSize: 22, color: _ink)),
            SizedBox(height: 8),
            _Banner(text: _achievement, width: 560),
            SizedBox(height: 6),
            Text('بتقدير', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: _ink)),
            SizedBox(height: 6),
            _Banner(text: '${cert.grade} · ${ar(cert.hifz)}٪', width: 380, small: true),
            SizedBox(height: 12),
            Text('سائلين الله أن يجعل القرآن الكريم ربيع قلبه ونور صدره، وأن يبارك في جهوده ويزيده علمًا وهدى.',
                textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontSize: 18.5, color: _ink, height: 1.6)),
            Spacer(),
            _footer(),
          ]),
        ),
      ];

  Widget _stats() {
    final items = <(String, String)>[
      (cert.kind == 'surah' ? 'الاختبار' : 'النتيجة', '${ar(cert.hifz)}٪'),
      if (cert.kind == 'surah') ('الآيات المتقنة', '${ar(cert.accuracy)}٪'),
      ('التقدير', cert.grade),
    ];
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (final it in items)
        Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          padding: EdgeInsets.symmetric(horizontal: 22, vertical: 6),
          decoration: BoxDecoration(
            color: Color(0x80FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _gold.withOpacity(0.7)),
          ),
          child: Column(children: [
            Text(it.$2, style: TextStyle(fontFamily: 'Amiri', fontSize: 24, fontWeight: FontWeight.w700, color: _green)),
            Text(it.$1, style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: _ink)),
          ]),
        ),
    ]);
  }

  Widget _footer() {
    Widget col(IconData i, String label, String value) => Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _gold, width: 1.5)),
            child: Icon(i, color: _goldDeep, size: 20),
          ),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: _ink)),
          Text(value, style: TextStyle(fontFamily: 'Readex', fontSize: 13, color: _green)),
        ]);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      col(Icons.calendar_month_rounded, 'التاريخ', cert.date),
      Column(mainAxisSize: MainAxisSize.min, children: [
        CustomPaint(size: Size(46, 46), painter: _MiniStar()),
        Text('سند', style: TextStyle(fontFamily: 'Ruqaa', fontSize: 28, fontWeight: FontWeight.w700, color: _green, height: 1.1)),
        Text('تعلّم · احفظ · تفقّه', style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: _goldDeep)),
      ]),
      col(Icons.verified_rounded, 'رمز الشهادة', cert.code),
    ]);
  }

  Widget _ornLine() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(width: 140, height: 1.5, color: _gold),
        SizedBox(width: 10),
        _diamond(),
        SizedBox(width: 10),
        Container(width: 140, height: 1.5, color: _gold),
      ]);

  Widget _diamond() => Transform.rotate(
        angle: math.pi / 4,
        child: Container(width: 12, height: 12, decoration: BoxDecoration(color: _gold, border: Border.all(color: _goldDeep))),
      );
}

/// شريط أخضر بحواف ذهبية وأطراف مدببة.
class _Banner extends StatelessWidget {
  final String text;
  final double width;
  final bool small;
  const _Banner({required this.text, required this.width, this.small = false});

  @override
  Widget build(BuildContext context) {
    final h = small ? 54.0 : 66.0;
    return CustomPaint(
      painter: _BannerPainter(),
      child: SizedBox(
        width: width,
        height: h,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 46),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: small ? 26 : 30, fontWeight: FontWeight.w700, color: Color(0xFFFFF8E6))),
            ),
          ),
        ),
      ),
    );
  }
}

class _BannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final n = s.height * 0.42;
    Path shape(double inset) {
      final w = s.width, h = s.height;
      return Path()
        ..moveTo(n + inset, inset)
        ..lineTo(w - n - inset, inset)
        ..lineTo(w - inset, h / 2)
        ..lineTo(w - n - inset, h - inset)
        ..lineTo(n + inset, h - inset)
        ..lineTo(inset, h / 2)
        ..close();
    }

    canvas.drawPath(shape(0), Paint()..color = _gold);
    canvas.drawPath(
        shape(4),
        Paint()
          ..shader = LinearGradient(colors: [_green, _greenDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Offset.zero & s));
    canvas.drawPath(
        shape(8),
        Paint()
          ..color = _gold.withOpacity(0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// الإطار الذهبي المزدوج مع زخارف الأركان والأشرطة الركنية.
class _FramePainter extends CustomPainter {
  final bool bands;
  _FramePainter({required this.bands});

  @override
  void paint(Canvas canvas, Size s) {
    if (bands) {
      // شريطان قطريان في الركن العلوي الأيمن والسفلي الأيسر
      void band(Offset a, Offset b, Offset c) {
        canvas.drawPath(Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(c.dx, c.dy)..close(), Paint()..color = _green);
      }

      band(Offset(s.width - 230, 0), Offset(s.width, 0), Offset(s.width, 230));
      band(Offset(0, s.height - 230), Offset(0, s.height), Offset(230, s.height));
      final g = Paint()
        ..color = _gold
        ..strokeWidth = 14;
      canvas.drawLine(Offset(s.width - 260, 0), Offset(s.width, 260), g);
      canvas.drawLine(Offset(0, s.height - 260), Offset(260, s.height), g);
      final g2 = Paint()
        ..color = Color(0xFFE6C77E)
        ..strokeWidth = 3;
      canvas.drawLine(Offset(s.width - 238, 0), Offset(s.width, 238), g2);
      canvas.drawLine(Offset(0, s.height - 238), Offset(238, s.height), g2);
    }
    final outer = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final inner = Paint()
      ..color = _goldDeep.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(18, 18, s.width - 36, s.height - 36), Radius.circular(6)), outer);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(30, 30, s.width - 60, s.height - 60), Radius.circular(4)), inner);
    for (final c in [Offset(30, 30), Offset(s.width - 30, 30), Offset(30, s.height - 30), Offset(s.width - 30, s.height - 30)]) {
      _corner(canvas, c);
    }
  }

  void _corner(Canvas canvas, Offset c) {
    final p = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var k = 0; k < 4; k++) {
        final a = rot + math.pi / 4 + k * math.pi / 2;
        final pt = Offset(c.dx + 16 * math.cos(a), c.dy + 16 * math.sin(a));
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(c, 5, Paint()..color = _gold);
    canvas.drawCircle(c, 26, p..strokeWidth = 0.8);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ختم دائري ذهبي وأخضر مع شريطين.
class _Seal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 190,
      child: CustomPaint(
        painter: _SealPainter(),
        child: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('سند', style: TextStyle(fontFamily: 'Ruqaa', fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFFF1D58E), height: 1.1)),
              Text('★ ★ ★', style: TextStyle(fontSize: 10, color: Color(0xFFF1D58E))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, 75);
    // الشريطان
    final rib = Paint()..color = _green;
    canvas.drawPath(Path()..moveTo(c.dx - 30, c.dy + 40)..lineTo(c.dx - 50, s.height)..lineTo(c.dx - 30, s.height - 16)..lineTo(c.dx - 12, s.height)..lineTo(c.dx, c.dy + 50)..close(), rib);
    canvas.drawPath(Path()..moveTo(c.dx + 30, c.dy + 40)..lineTo(c.dx + 50, s.height)..lineTo(c.dx + 30, s.height - 16)..lineTo(c.dx + 12, s.height)..lineTo(c.dx, c.dy + 50)..close(), rib);
    // الحافة المسننة
    final gp = Paint()..color = _gold;
    for (var i = 0; i < 28; i++) {
      final a = i * 2 * math.pi / 28;
      canvas.drawCircle(Offset(c.dx + 68 * math.cos(a), c.dy + 68 * math.sin(a)), 8, gp);
    }
    canvas.drawCircle(c, 68, gp);
    canvas.drawCircle(c, 58, Paint()..color = _greenDeep);
    canvas.drawCircle(
        c,
        52,
        Paint()
          ..color = _gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// لوحة القوس الجانبية مع آية «ورتل القرآن ترتيلا».
class _ArchPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArchPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 90, 16, 30),
        child: Column(children: [
          Text('وَرَتِّلِ\nٱلْقُرْءَانَ\nتَرْتِيلًا',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 34, color: Color(0xFFF1D58E), height: 1.9)),
          Spacer(),
          CustomPaint(size: Size(54, 54), painter: _MiniStar(color: Color(0xFFF1D58E))),
        ]),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    Path arch(double i) => Path()
      ..moveTo(i, s.height - i)
      ..lineTo(i, s.width * 0.55)
      ..quadraticBezierTo(i, i, s.width / 2, i)
      ..quadraticBezierTo(s.width - i, i, s.width - i, s.width * 0.55)
      ..lineTo(s.width - i, s.height - i)
      ..close();
    canvas.drawPath(arch(0), Paint()..color = _gold);
    canvas.drawPath(
        arch(6),
        Paint()
          ..shader = LinearGradient(colors: [_green, _greenDeep], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Offset.zero & s));
    canvas.drawPath(
        arch(14),
        Paint()
          ..color = _gold.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiniStar extends CustomPainter {
  final Color color;
  _MiniStar({this.color = _gold});

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width * 0.42;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var k = 0; k < 4; k++) {
        final a = rot + math.pi / 4 + k * math.pi / 2;
        final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
    canvas.drawCircle(c, r * 0.25, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
