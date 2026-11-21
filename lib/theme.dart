import 'package:flutter/material.dart';

/// ألوان التطبيق — مطابقة لتصميم Claude Design.
class C {
  static const bg = Color(0xFF0C1A16);
  static const surface = Color(0xFF13261F);
  static const surface2 = Color(0xFF1A3229);
  static const deep = Color(0xFF10221C);
  static const nav = Color(0xFF0F211C);
  static const line = Color(0xFF24433A);
  static const line2 = Color(0xFF2C5245);
  static const gold = Color(0xFFE3BB64);
  static const goldSoft = Color(0xFF3A3018);
  static const onGold = Color(0xFF1A1406);
  static const text = Color(0xFFF3EFE4);
  static const muted = Color(0xFFA3B8AF);
  static const green = Color(0xFF5FD3A0);
  static const greenSoft = Color(0xFF1F3D32);
  static const red = Color(0xFFFF7A6B);
  static const redSoft = Color(0xFF2A1714);
  static const redLine = Color(0xFF5A2A23);
  static const blue = Color(0xFF7FC4F0);
  static const blueSoft = Color(0xFF1D3240);
  static const purple = Color(0xFFC49BFF);
  static const coral = Color(0xFFFF9B7A);
  static const coralSoft = Color(0xFF3A2420);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Readex',
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.gold,
      onPrimary: C.onGold,
      secondary: C.green,
      surface: C.surface,
      onSurface: C.text,
      error: C.red,
    ),
  );
  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.text,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(fontFamily: 'Readex', fontSize: 17, fontWeight: FontWeight.w600, color: C.text),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.surface2,
      contentTextStyle: TextStyle(fontFamily: 'Readex', color: C.text),
      behavior: SnackBarBehavior.floating,
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: C.surface),
  );
}

const _arDigits = '٠١٢٣٤٥٦٧٨٩';

/// تحويل الأرقام إلى أرقام عربية مشرقية.
String ar(Object n) => n.toString().replaceAllMapped(RegExp(r'[0-9]'), (m) => _arDigits[int.parse(m[0]!)]);

const quranStyle = TextStyle(fontFamily: 'AmiriQuran', color: C.text, height: 2.1);

/// صندوق بخلفية وحد — أساس كل البطاقات.
class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color border;
  final double radius;
  final VoidCallback? onTap;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = C.surface,
    this.border = C.line,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: box),
    );
  }
}

class GoldButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;
  final double height;
  const GoldButton({super.key, required this.label, this.icon, this.onPressed, this.outlined = false, this.height = 54});

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? C.text : C.onGold;
    return SizedBox(
      height: height,
      child: Material(
        color: outlined ? C.surface : (onPressed == null ? C.line : C.gold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: outlined ? const BorderSide(color: C.line2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 15, fontWeight: outlined ? FontWeight.w500 : FontWeight.w600)),
              ),
            ],
          ),
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
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class ProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const ProgressBar({super.key, required this.value, this.color = C.gold, this.height = 6});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: C.bg,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class Tag extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const Tag(this.text, {super.key, this.fg = C.muted, this.bg = C.surface2});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 11.5, color: fg)),
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
