import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

/// الثيمات الخمسة.
const appThemes = <AppTheme>[
  // ١. الزمرد الذهبي — أخضر غامق وذهبي
  AppTheme(
    id: 'emerald', name: 'الزمرد الذهبي', desc: 'أخضر زمردي غامق بلمسات ذهبية', dark: true,
    bg: Color(0xFF0A1714), bg2: Color(0xFF0E1F1A), surface: Color(0xFF13261F), surface2: Color(0xFF1A3229),
    deep: Color(0xFF0F211C), nav: Color(0xFF0D1D18), line: Color(0xFF22403A), line2: Color(0xFF2C5245),
    gold: Color(0xFFE3BB64), goldLight: Color(0xFFF3D58F), goldSoft: Color(0xFF3A3018), goldLine: Color(0xFF5C4B22), onGold: Color(0xFF1A1406),
    text: Color(0xFFF3EFE4), textSoft: Color(0xFFD3DED9), muted: Color(0xFFA3B8AF),
    green: Color(0xFF5FD3A0), greenSoft: Color(0xFF1F3D32), red: Color(0xFFFF7A6B), redSoft: Color(0xFF2A1714), redLine: Color(0xFF5A2A23),
    blue: Color(0xFF7FC4F0), blueSoft: Color(0xFF1D3240), purple: Color(0xFFC49BFF), purpleSoft: Color(0xFF2C2440),
    coral: Color(0xFFFF9B7A), coralSoft: Color(0xFF3A2420),
    heroA: Color(0xFF1E3B2F), heroB: Color(0xFF12241D), heroText: Color(0xFFF3EFE4), heroMuted: Color(0xFFA3B8AF),
    heroAccent: Color(0xFFE3BB64), highlight: Color(0xFF1B2F22), pattern: Color(0xFFE3BB64),
  ),
  // ٢. ليالي رمضان — أزرق هادئ وكروت بيضاء
  AppTheme(
    id: 'ramadan', name: 'ليالي رمضان', desc: 'أزرق سماوي هادئ مع كروت بيضاء', dark: false,
    bg: Color(0xFFE3ECF2), bg2: Color(0xFFF1F6F9), surface: Color(0xFFFFFFFF), surface2: Color(0xFFEDF3F7),
    deep: Color(0xFFF4F8FB), nav: Color(0xFF2B6488), line: Color(0xFFD5E2EA), line2: Color(0xFFB8CEDB),
    gold: Color(0xFF2D6A90), goldLight: Color(0xFF4A8DB5), goldSoft: Color(0xFFDCEAF3), goldLine: Color(0xFFA9C8DB), onGold: Color(0xFFFFFFFF),
    text: Color(0xFF16324A), textSoft: Color(0xFF2E4A60), muted: Color(0xFF5F7B8E),
    green: Color(0xFF26935F), greenSoft: Color(0xFFDDF1E6), red: Color(0xFFD64535), redSoft: Color(0xFFFBE5E2), redLine: Color(0xFFF0B9B1),
    blue: Color(0xFF2F7FC1), blueSoft: Color(0xFFDDEBF8), purple: Color(0xFF6E58C6), purpleSoft: Color(0xFFE8E3F8),
    coral: Color(0xFFD9653F), coralSoft: Color(0xFFFBE7DE),
    heroA: Color(0xFF3B7FA6), heroB: Color(0xFF1F4E6D), heroText: Color(0xFFFFFFFF), heroMuted: Color(0xFFCFE2EE),
    heroAccent: Color(0xFFFFFFFF), highlight: Color(0xFFE4F0F8), pattern: Color(0xFFFFFFFF),
  ),
  // ٣. النعناع — فيروزي مشرق وكروت ملونة
  AppTheme(
    id: 'mint', name: 'النعناع', desc: 'فيروزي مشرق مع أقسام ملونة مبهجة', dark: false,
    bg: Color(0xFFEFF7F5), bg2: Color(0xFFF8FCFB), surface: Color(0xFFFFFFFF), surface2: Color(0xFFEAF5F3),
    deep: Color(0xFFF4FAF9), nav: Color(0xFFFFFFFF), line: Color(0xFFD6EAE6), line2: Color(0xFFB5DCD5),
    gold: Color(0xFF15A898), goldLight: Color(0xFF3CC7B6), goldSoft: Color(0xFFD5F2EE), goldLine: Color(0xFF9EDDD4), onGold: Color(0xFFFFFFFF),
    text: Color(0xFF1C3633), textSoft: Color(0xFF34504C), muted: Color(0xFF66807C),
    green: Color(0xFF1E9E5E), greenSoft: Color(0xFFDDF3E6), red: Color(0xFFE0483A), redSoft: Color(0xFFFDE6E3), redLine: Color(0xFFF5BBB3),
    blue: Color(0xFF2E9BDB), blueSoft: Color(0xFFDDF0FB), purple: Color(0xFF8A63DD), purpleSoft: Color(0xFFEEE6FB),
    coral: Color(0xFFEC5E93), coralSoft: Color(0xFFFCE3EE),
    heroA: Color(0xFF26C2B0), heroB: Color(0xFF119184), heroText: Color(0xFFFFFFFF), heroMuted: Color(0xFFD8F5F1),
    heroAccent: Color(0xFFFFFFFF), highlight: Color(0xFFE2F6F3), pattern: Color(0xFFFFFFFF),
  ),
  // ٤. الباستيل — أبيض ورأس فيروزي وأقسام باستيل
  AppTheme(
    id: 'pastel', name: 'الباستيل', desc: 'أبيض ناعم مع ألوان باستيل هادئة', dark: false,
    bg: Color(0xFFF7F9FA), bg2: Color(0xFFFFFFFF), surface: Color(0xFFFFFFFF), surface2: Color(0xFFF1F5F6),
    deep: Color(0xFFF6F9FA), nav: Color(0xFFFFFFFF), line: Color(0xFFE3EAEC), line2: Color(0xFFCFDCE0),
    gold: Color(0xFF17ACA3), goldLight: Color(0xFF45C4BC), goldSoft: Color(0xFFDDF3F1), goldLine: Color(0xFFA6DEDA), onGold: Color(0xFFFFFFFF),
    text: Color(0xFF223A4A), textSoft: Color(0xFF3B5464), muted: Color(0xFF6E8592),
    green: Color(0xFF3A9E74), greenSoft: Color(0xFFDDF2E8), red: Color(0xFFDB5A4B), redSoft: Color(0xFFFBE7E3), redLine: Color(0xFFF2C0B8),
    blue: Color(0xFF4D86D6), blueSoft: Color(0xFFDFEAFA), purple: Color(0xFF8B74D6), purpleSoft: Color(0xFFEAE5F8),
    coral: Color(0xFFE5845F), coralSoft: Color(0xFFFCE8DD),
    heroA: Color(0xFF1DB6AC), heroB: Color(0xFF15A299), heroText: Color(0xFFFFFFFF), heroMuted: Color(0xFFDDF6F4),
    heroAccent: Color(0xFFFFFFFF), highlight: Color(0xFFE6F6F5), pattern: Color(0xFFFFFFFF),
  ),
  // ٥. نور — كريمي دافئ وأخضر زيتي وذهبي
  AppTheme(
    id: 'noor', name: 'نور', desc: 'كريمي دافئ مع أخضر زيتي وذهبي', dark: false,
    bg: Color(0xFFF3ECE0), bg2: Color(0xFFF9F5EE), surface: Color(0xFFFCF8F1), surface2: Color(0xFFF0E7D8),
    deep: Color(0xFFF7F1E6), nav: Color(0xFFFCF8F1), line: Color(0xFFE6DAC5), line2: Color(0xFFD7C6A8),
    gold: Color(0xFF3E5E4B), goldLight: Color(0xFF5E806B), goldSoft: Color(0xFFE4E9DD), goldLine: Color(0xFFC9B48A), onGold: Color(0xFFFFF8EC),
    text: Color(0xFF2E3A30), textSoft: Color(0xFF45524A), muted: Color(0xFF7D7A6B),
    green: Color(0xFF3E7D58), greenSoft: Color(0xFFE2EDE3), red: Color(0xFFC0503E), redSoft: Color(0xFFF7E3DD), redLine: Color(0xFFE8BDB2),
    blue: Color(0xFF4B7FA3), blueSoft: Color(0xFFE2EBF1), purple: Color(0xFF8A6AA8), purpleSoft: Color(0xFFEDE5F1),
    coral: Color(0xFFB8893B), coralSoft: Color(0xFFF4E8D1),
    heroA: Color(0xFF4A6B56), heroB: Color(0xFF34503F), heroText: Color(0xFFFFF8EC), heroMuted: Color(0xFFDCD3BE),
    heroAccent: Color(0xFFE2C27F), highlight: Color(0xFFEFE6D2), pattern: Color(0xFFE2C27F),
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
  static Color get navActive => t.id == 'ramadan' ? Color(0xFFFFFFFF) : t.gold;
  static Color get navIdle => t.id == 'ramadan' ? Color(0xFFB9D3E3) : t.muted;
  static Color get navPill => t.id == 'ramadan' ? Color(0x33FFFFFF) : t.goldSoft;

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

/// رأس صفحة بزخرفة إسلامية بألوان الثيم.
class HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Color? color;
  const HeroHeader({super.key, required this.title, required this.subtitle, this.trailing, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? C.heroAccent;
    final colors = C.dark ? [Color.lerp(C.surface2, tint, 0.16)!, C.surface] : [C.heroA, C.heroB];
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: colors),
          border: Border.all(color: C.dark ? tint.withOpacity(0.3) : Colors.transparent),
          borderRadius: BorderRadius.circular(26),
          boxShadow: C.dark ? null : [BoxShadow(color: C.heroB.withOpacity(0.3), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: C.pattern, opacity: C.dark ? 0.07 : 0.12))),
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: C.heroText)),
                  SizedBox(height: 6),
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
