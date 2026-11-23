import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// هوية التطبيق
const kAppName = 'سَنَد';
const kEmblem = 'assets/brand/emblem.png';
const kDeveloper = 'Mohamed-Eldawly';
/// نسخة جوجل بلاي: التحديث من المتجر، فمفيش تحديث داخلي
const kStore = bool.fromEnvironment('STORE');

/// لوحة ألوان ثيم كامل.
class AppTheme {
  final String id;
  final String name;
  final String desc;
  final bool dark;
  final Color bg, bg2, surface, surface2, deep, nav, line, line2;
  final Color gold, goldLight, goldSoft, goldLine, onGold;
  final Color text, textSoft, muted;
  final Color green, greenSoft, red, redSoft, redLine, blue, blueSoft, purple, purpleSoft, coral, coralSoft;
  final Color heroA, heroB, heroText, heroMuted, heroAccent, highlight, pattern;
  const AppTheme({
    required this.id,
    required this.name,
    required this.desc,
    required this.dark,
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.deep,
    required this.nav,
    required this.line,
    required this.line2,
    required this.gold,
    required this.goldLight,
    required this.goldSoft,
    required this.goldLine,
    required this.onGold,
    required this.text,
    required this.textSoft,
    required this.muted,
    required this.green,
    required this.greenSoft,
    required this.red,
    required this.redSoft,
    required this.redLine,
    required this.blue,
    required this.blueSoft,
    required this.purple,
    required this.purpleSoft,
    required this.coral,
    required this.coralSoft,
    required this.heroA,
    required this.heroB,
    required this.heroText,
    required this.heroMuted,
    required this.heroAccent,
    required this.highlight,
    required this.pattern,
  });
}

/// الثيمات الخمسة (الترتيب ثابت لأن رقم الثيم محفوظ عند المستخدم).
const appThemes = <AppTheme>[
  // ١. الزمرد الذهبي — أخضر زمردي غامق وذهبي
  AppTheme(
    id: 'emerald', name: 'الزمرد الذهبي', desc: 'أخضر زمردي غامق بلمسات ذهبية', dark: true,
    bg: Color(0xFF0A2B25), bg2: Color(0xFF0F3D34), surface: Color(0xFF10362E), surface2: Color(0xFF174A3B), deep: Color(0xFF0B2F28), nav: Color(0xFF071E1A), line: Color(0xFF2A5446), line2: Color(0xFF4A6B4E), gold: Color(0xFFE7C77B), goldLight: Color(0xFFF2D68E), goldSoft: Color(0xFF3A3418), goldLine: Color(0xFF6B5826), onGold: Color(0xFF2A1E07), text: Color(0xFFF5EBD3), textSoft: Color(0xFFDCCFA9), muted: Color(0xFFA9B9A8), green: Color(0xFF6FE0AE), greenSoft: Color(0xFF1B4A3C), red: Color(0xFFFF7A6B), redSoft: Color(0xFF3A1F1A), redLine: Color(0xFF6A2E26), blue: Color(0xFF7FD3E0), blueSoft: Color(0xFF16424A), purple: Color(0xFFC9A8FF), purpleSoft: Color(0xFF2E2A48), coral: Color(0xFFFFB36B), coralSoft: Color(0xFF3E2E1A), heroA: Color(0xFF2B7A60), heroB: Color(0xFF174A3B), heroText: Color(0xFFF5EBD3), heroMuted: Color(0xFFCFE3D6), heroAccent: Color(0xFFF2D68E), highlight: Color(0xFF1B4A3C), pattern: Color(0xFFE7C77B),
  ),
  // ٢. ليالي رمضان — كحلي ليلي وذهبي فانوسي
  AppTheme(
    id: 'ramadan', name: 'ليالي رمضان', desc: 'كحلي ليلي مع ذهبي الفوانيس', dark: true,
    bg: Color(0xFF0C1433), bg2: Color(0xFF16204A), surface: Color(0xFF1A2756), surface2: Color(0xFF22326A), deep: Color(0xFF121C42), nav: Color(0xFF0A102C), line: Color(0xFF2A3A72), line2: Color(0xFF3A4C8A), gold: Color(0xFFF4C95D), goldLight: Color(0xFFFFDD85), goldSoft: Color(0xFF3A3420), goldLine: Color(0xFF6E5A26), onGold: Color(0xFF241A05), text: Color(0xFFEEF1FF), textSoft: Color(0xFFDCE1FA), muted: Color(0xFFAEB8E6), green: Color(0xFF7FE3B0), greenSoft: Color(0xFF1C3A3A), red: Color(0xFFFF8A7A), redSoft: Color(0xFF3A1E2A), redLine: Color(0xFF6A3040), blue: Color(0xFF8FB8FF), blueSoft: Color(0xFF1E2E5E), purple: Color(0xFFC4A8FF), purpleSoft: Color(0xFF2C2656), coral: Color(0xFFFFB36B), coralSoft: Color(0xFF3A2A26), heroA: Color(0xFF2A3C86), heroB: Color(0xFF18245A), heroText: Color(0xFFEEF1FF), heroMuted: Color(0xFFAEB8E6), heroAccent: Color(0xFFF4C95D), highlight: Color(0xFF22326A), pattern: Color(0xFFF4C95D),
  ),
  // ٣. رمال — بيج وبني وذهبي
  AppTheme(
    id: 'sand', name: 'رمال', desc: 'بيج دافئ مع بني وذهبي', dark: false,
    bg: Color(0xFFF3EADB), bg2: Color(0xFFF8F1E4), surface: Color(0xFFFBF6EC), surface2: Color(0xFFF1E5CF), deep: Color(0xFFF6EEDF), nav: Color(0xFFFBF6EC), line: Color(0xFFE4D3B4), line2: Color(0xFFD2BC93), gold: Color(0xFF6B4A32), goldLight: Color(0xFF8A6446), goldSoft: Color(0xFFF1E2C6), goldLine: Color(0xFFD9B978), onGold: Color(0xFFF4DFAE), text: Color(0xFF3B2618), textSoft: Color(0xFF5A4430), muted: Color(0xFF8C7458), green: Color(0xFF4E8A5A), greenSoft: Color(0xFFE3EDDC), red: Color(0xFFB5483A), redSoft: Color(0xFFF6E1DA), redLine: Color(0xFFE5B8AC), blue: Color(0xFF4A6F94), blueSoft: Color(0xFFE1E8EF), purple: Color(0xFF85608F), purpleSoft: Color(0xFFEDE2EE), coral: Color(0xFFB8862F), coralSoft: Color(0xFFF4E6C8), heroA: Color(0xFF6B4A32), heroB: Color(0xFF3E2A1C), heroText: Color(0xFFFBF1DD), heroMuted: Color(0xFFE2CDA6), heroAccent: Color(0xFFE8C77E), highlight: Color(0xFFF1E2C6), pattern: Color(0xFFE8C77E),
  ),
  // ٤. لؤلؤ — أبيض وكحلي وذهبي
  AppTheme(
    id: 'pearl', name: 'لؤلؤ', desc: 'أبيض ناصع مع كحلي وذهبي', dark: false,
    bg: Color(0xFFF4F7FC), bg2: Color(0xFFFFFFFF), surface: Color(0xFFFFFFFF), surface2: Color(0xFFEEF2FA), deep: Color(0xFFF7F9FD), nav: Color(0xFFFFFFFF), line: Color(0xFFE1E7F2), line2: Color(0xFFC9D4E8), gold: Color(0xFF1E3F75), goldLight: Color(0xFF2F5FA8), goldSoft: Color(0xFFE4EBF7), goldLine: Color(0xFFE9CD86), onGold: Color(0xFFFFFFFF), text: Color(0xFF13254A), textSoft: Color(0xFF2C3E63), muted: Color(0xFF6B7A99), green: Color(0xFF2E8A63), greenSoft: Color(0xFFDDF1E7), red: Color(0xFFC4483C), redSoft: Color(0xFFFBE6E3), redLine: Color(0xFFF0BDB6), blue: Color(0xFF2F6FCB), blueSoft: Color(0xFFE0EBFA), purple: Color(0xFF6D5BC4), purpleSoft: Color(0xFFE9E5F8), coral: Color(0xFFC98A2A), coralSoft: Color(0xFFFBF0DC), heroA: Color(0xFF1E3F75), heroB: Color(0xFF12264A), heroText: Color(0xFFFFFFFF), heroMuted: Color(0xFFC9D5EE), heroAccent: Color(0xFFE9CD86), highlight: Color(0xFFFBF3DF), pattern: Color(0xFFE9CD86),
  ),
  // ٥. نور — كريمي وأخضر وذهبي
  AppTheme(
    id: 'noor', name: 'نور', desc: 'كريمي هادئ مع أخضر وذهبي', dark: false,
    bg: Color(0xFFF7F1E3), bg2: Color(0xFFFBF7EE), surface: Color(0xFFFFFDF7), surface2: Color(0xFFF1E8D3), deep: Color(0xFFFAF5EA), nav: Color(0xFFFFFDF7), line: Color(0xFFEADFC2), line2: Color(0xFFDCCB9F), gold: Color(0xFF1F6B4F), goldLight: Color(0xFF2E8A66), goldSoft: Color(0xFFE6F1EB), goldLine: Color(0xFFC9B48A), onGold: Color(0xFFFFFDF7), text: Color(0xFF2B2A22), textSoft: Color(0xFF45433A), muted: Color(0xFF8A7A4E), green: Color(0xFF1F8A5C), greenSoft: Color(0xFFE2F0E7), red: Color(0xFFB8503E), redSoft: Color(0xFFF7E3DD), redLine: Color(0xFFE8BDB2), blue: Color(0xFF2C6E78), blueSoft: Color(0xFFE3EEF0), purple: Color(0xFF8A6AA8), purpleSoft: Color(0xFFEDE5F1), coral: Color(0xFFA07A22), coralSoft: Color(0xFFF6EBCF), heroA: Color(0xFF1F6B4F), heroB: Color(0xFF174F3B), heroText: Color(0xFFFFFDF7), heroMuted: Color(0xFFE7F0EA), heroAccent: Color(0xFFF3E3AE), highlight: Color(0xFFF1E6C8), pattern: Color(0xFFE9D9A6),
  ),
];

/// ألوان التطبيق للثيم الحالي.
class C {
  static AppTheme t = appThemes.first;
  static bool get dark => t.dark;
  static Color get bg => t.bg;
  static Color get bg2 => t.bg2;
  static Color get surface => t.surface;
  static Color get surface2 => t.surface2;
  static Color get deep => t.deep;
  static Color get nav => t.nav;
  static Color get line => t.line;
  static Color get line2 => t.line2;
  static Color get gold => t.gold;
  static Color get goldLight => t.goldLight;
  static Color get goldSoft => t.goldSoft;
  static Color get goldLine => t.goldLine;
  static Color get onGold => t.onGold;
  static Color get text => t.text;
  static Color get textSoft => t.textSoft;
  static Color get muted => t.muted;
  static Color get green => t.green;
  static Color get greenSoft => t.greenSoft;
  static Color get red => t.red;
  static Color get redSoft => t.redSoft;
  static Color get redLine => t.redLine;
  static Color get blue => t.blue;
  static Color get blueSoft => t.blueSoft;
  static Color get purple => t.purple;
  static Color get purpleSoft => t.purpleSoft;
  static Color get coral => t.coral;
  static Color get coralSoft => t.coralSoft;
  static Color get heroA => t.heroA;
  static Color get heroB => t.heroB;
  static Color get heroText => t.heroText;
  static Color get heroMuted => t.heroMuted;
  static Color get heroAccent => t.heroAccent;
  static Color get highlight => t.highlight;
  static Color get pattern => t.pattern;
  /// لون شريط التنقل للأيقونة النشطة
  static Color get navActive => t.onGold;
  static Color get navIdle => t.muted;
  static Color get navPill => t.gold;
  /// تدرّج الأزرار والعناصر النشطة: ذهبي في الثيمات الغامقة، واللون الأساسي في الفاتحة
  static List<Color> get goldGrad => [Color.lerp(t.gold, Colors.white, 0.2)!, t.gold];

  static Color accent(String name) {
    switch (name) {
      case 'blue':
        return blue;
      case 'green':
        return green;
      case 'purple':
        return purple;
      case 'coral':
        return coral;
      default:
        return gold;
    }
  }

  static Color accentSoft(String name) {
    switch (name) {
      case 'blue':
        return blueSoft;
      case 'green':
        return greenSoft;
      case 'purple':
        return purpleSoft;
      case 'coral':
        return coralSoft;
      default:
        return goldSoft;
    }
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: C.dark ? Brightness.dark : Brightness.light,
    fontFamily: 'Readex',
    scaffoldBackgroundColor: C.bg,
    splashFactory: InkSparkle.splashFactory,
    colorScheme: C.dark
        ? ColorScheme.dark(primary: C.gold, onPrimary: C.onGold, secondary: C.green, surface: C.surface, onSurface: C.text, error: C.red)
        : ColorScheme.light(primary: C.gold, onPrimary: C.onGold, secondary: C.green, surface: C.surface, onSurface: C.text, error: C.red),
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: C.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Readex', fontSize: 17, fontWeight: FontWeight.w600, color: C.text),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.dark ? C.surface2 : C.text,
      contentTextStyle: TextStyle(fontFamily: 'Readex', color: C.dark ? C.text : C.surface),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: C.surface, surfaceTintColor: Colors.transparent),
    dividerColor: C.line,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    }),
  );
}

const _arDigits = '٠١٢٣٤٥٦٧٨٩';

/// تحويل الأرقام إلى أرقام عربية مشرقية.
String ar(Object n) => n.toString().replaceAllMapped(RegExp(r'[0-9]'), (m) => _arDigits[int.parse(m[0]!)]);

TextStyle get quranStyle => TextStyle(fontFamily: 'AmiriQuran', color: C.text, height: 2.1);

/// خلفية التطبيق بتدرج هادئ.
class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [C.bg2, C.bg],
        ),
      ),
      child: child,
    );
  }
}

/// صفحة بخلفية التطبيق وشريط علوي شفاف.
class AppPage extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottom;
  const AppPage({super.key, this.title, required this.body, this.actions, this.bottom});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: title == null ? null : Text(title!), actions: actions),
        body: SafeArea(top: false, child: body),
        bottomNavigationBar: bottom,
      ),
    );
  }
}

/// زخرفة نجمة ثمانية تُستخدم في الخلفيات.
class StarPatternPainter extends CustomPainter {
  final Color color;
  final double opacity;
  StarPatternPainter({Color? color, this.opacity = 0.08}) : color = color ?? C.pattern;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    const step = 64.0;
    for (double y = -step; y < size.height + step; y += step) {
      for (double x = -step; x < size.width + step; x += step) {
        final dx = ((y / step).round().isOdd) ? step / 2 : 0.0;
        _star(canvas, Offset(x + dx, y), 18, p);
      }
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    for (final rot in [0.0, math.pi / 4]) {
      final path = Path();
      for (var k = 0; k < 4; k++) {
        final a = rot + math.pi / 4 + k * math.pi / 2;
        final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
        if (k == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      c.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// زر يصغر قليلًا عند الضغط مع اهتزاز خفيف.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// بطاقة أساسية.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? border;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.border,
    this.radius = 20,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? C.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? C.line),
        boxShadow: [BoxShadow(color: C.dark ? Color(0x33000000) : Color(0x14223A4A), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Pressable(onTap: onTap, child: box);
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final double height;
  final Color? color;
  final Color? fg;
  const GoldButton(
      {super.key, required this.label, this.icon, this.onPressed, this.outlined = false, this.height = 54, this.color, this.fg});

  @override
  Widget build(BuildContext context) {
    final base = color ?? C.gold;
    final fg = this.fg ?? (outlined ? C.text : C.onGold);
    return Pressable(
      onTap: onPressed,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: outlined ? C.surface : (onPressed == null ? C.line : null),
          gradient: outlined || onPressed == null
              ? null
              : LinearGradient(colors: [Color.lerp(base, Colors.white, 0.18)!, base]),
          border: outlined ? Border.all(color: C.line2) : null,
          boxShadow: outlined || onPressed == null
              ? null
              : [BoxShadow(color: base.withOpacity(0.28), blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20, color: fg), SizedBox(width: 8)],
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg, fontSize: 15, fontWeight: outlined ? FontWeight.w500 : FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final double size;
  const IconBox({super.key, required this.icon, required this.color, required this.bg, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color.lerp(bg, color, 0.18)!, bg],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const ProgressBar({super.key, required this.value, this.color, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: C.dark ? C.bg : C.line,
          valueColor: AlwaysStoppedAnimation(color ?? C.gold),
        ),
      ),
    );
  }
}

/// حلقة تقدم متحركة مع رقم في المنتصف.
class ScoreRing extends StatelessWidget {
  final double value;
  final double size;
  final Color? color;
  final String label;
  final String? sub;
  const ScoreRing({super.key, required this.value, this.size = 110, this.color, required this.label, this.sub});

  @override
  Widget build(BuildContext context) {
    final onHero = context.dependOnInheritedWidgetOfExactType<_OnHero>() != null;
    final color = onHero ? C.heroAccent : (this.color ?? C.gold);
    final track = onHero ? C.heroText.withOpacity(0.18) : (C.dark ? C.bg : C.line);
    final subColor = onHero ? C.heroMuted : C.muted;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: v,
              strokeWidth: size * 0.09,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(label, style: TextStyle(fontSize: size * 0.26, fontWeight: FontWeight.w700, color: color)),
            if (sub != null) Text(sub!, style: TextStyle(fontSize: size * 0.1, color: subColor)),
          ]),
        ]),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color? fg;
  final Color? bg;
  const Tag(this.text, {super.key, this.fg, this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg ?? C.surface2, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 11.5, color: fg ?? C.muted)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 6, bottom: 10),
      child: Row(children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(4))),
        SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

class _OnHero extends InheritedWidget {
  const _OnHero({required super.child});
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// رأس صفحة بزخرفة إسلامية بألوان الثيم (تدرّج الهوية + إطار ذهبي + قوس وهلال).
class HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? color;
  const HeroHeader({super.key, required this.title, required this.subtitle, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [C.heroA, C.heroB]),
          border: Border.all(color: C.heroAccent.withOpacity(0.45), width: 1.2),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: C.heroB.withOpacity(C.dark ? 0.5 : 0.3), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: C.pattern, opacity: C.dark ? 0.09 : 0.13))),
          Positioned.fill(child: CustomPaint(painter: _HeroOrnament(C.heroAccent))),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontFamily: 'Amiri', fontSize: 27, height: 1.3, fontWeight: FontWeight.w700, color: C.heroAccent)),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: C.heroMuted, height: 1.6)),
                ]),
              ),
              if (trailing != null) _OnHero(child: trailing!),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// قوس ذهبي خفيف وهلال في ركن الرأس
class _HeroOrnament extends CustomPainter {
  final Color c;
  _HeroOrnament(this.c);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = c.withOpacity(0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    final x = w * 0.40, hw = h * 0.36;
    final arch = Path()
      ..moveTo(x - hw, h + 2)
      ..lineTo(x - hw, h * 0.55)
      ..quadraticBezierTo(x - hw, h * 0.12, x, h * 0.02)
      ..quadraticBezierTo(x + hw, h * 0.12, x + hw, h * 0.55)
      ..lineTo(x + hw, h + 2);
    canvas.drawPath(arch, p);
    final o = Offset(x, h * 0.42);
    final r = h * 0.14;
    final moon = Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: o, radius: r)),
        Path()..addOval(Rect.fromCircle(center: o + Offset(r * 0.42, -r * 0.18), radius: r * 0.86)));
    canvas.drawPath(moon, Paint()..color = c.withOpacity(0.35));
  }

  @override
  bool shouldRepaint(covariant _HeroOrnament old) => old.c != c;
}

extension EnterAnim on Widget {
  /// حركة دخول متدرجة للعناصر.
  Widget enter(int i) => animate()
      .fadeIn(duration: 380.ms, delay: (40 * i).clamp(0, 400).ms)
      .slideY(begin: 0.08, end: 0, duration: 420.ms, delay: (40 * i).clamp(0, 400).ms, curve: Curves.easeOutCubic);
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: 380),
      reverseTransitionDuration: Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

Future<T?> go<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(fadeRoute<T>(page));
