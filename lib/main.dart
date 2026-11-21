import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'data/quran.dart';
import 'data/progress.dart';
import 'data/course.dart';
import 'services/voice.dart';
import 'screens/home.dart';
import 'screens/surah_list.dart';
import 'screens/tajweed.dart';
import 'screens/library.dart';
import 'screens/arena.dart';
import 'widgets/update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Progress.load();
  final ti = Progress.themeIndex.clamp(0, appThemes.length - 1);
  C.t = appThemes[ti];
  Progress.themeNotifier.value = ti;
  runApp(MohafezApp());
}

bool _booted = false;

class MohafezApp extends StatefulWidget {
  const MohafezApp({super.key});

  @override
  State<MohafezApp> createState() => _MohafezAppState();
}

class _MohafezAppState extends State<MohafezApp> {
  @override
  void initState() {
    super.initState();
    Progress.themeNotifier.addListener(_onTheme);
  }

  void _onTheme() {
    final i = Progress.themeNotifier.value.clamp(0, appThemes.length - 1);
    setState(() => C.t = appThemes[i]);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: C.dark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: C.bg,
      systemNavigationBarIconBrightness: C.dark ? Brightness.light : Brightness.dark,
    ));
    return MaterialApp(
      key: ValueKey(C.t.id),
      title: 'المحفظ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _booted ? Shell() : Splash(),
    );
  }
}

/// شاشة البداية: شعار متحرك أثناء تحميل البيانات.
class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final t = Future.delayed(Duration(milliseconds: 1400));
    await Future.wait([QuranData.load(), Courses.load()]);
    _booted = true;
    Voice.init();
    TajweedData.load();
    await t;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => Shell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(opacity: 0.05))),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(painter: _LogoPainter()),
              )
                  .animate()
                  .scale(begin: Offset(0.6, 0.6), duration: 700.ms, curve: Curves.easeOutBack)
                  .then()
                  .rotate(begin: 0, end: 0.125, duration: 700.ms, curve: Curves.easeInOut),
              SizedBox(height: 24),
              Text('المحفظ', style: TextStyle(fontFamily: 'Amiri', fontSize: 40, fontWeight: FontWeight.w700, color: C.goldLight))
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              SizedBox(height: 6),
              Text('تعلّم · احفظ · تفقّه', style: TextStyle(color: C.muted, letterSpacing: 1))
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.42;
    final p = Paint()
      ..color = C.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawRect(Rect.fromCenter(center: c, width: r * 1.42, height: r * 1.42), p);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.785398);
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.42, height: r * 1.42), p);
    canvas.restore();
    canvas.drawCircle(c, r * 0.4, p);
    canvas.drawCircle(c, r * 0.15, Paint()..color = C.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> with WidgetsBindingObserver {
  int _tab = 0;
  DateTime? _lastCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // التحديث التلقائي: بعد ما التطبيق يفتح بثانيتين، وكل ما يرجع من الخلفية (مرة كل ٣ ساعات بالكتير)
    Future.delayed(Duration(seconds: 2), _autoCheck);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoCheck();
  }

  void _autoCheck() {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastCheck != null && now.difference(_lastCheck!) < Duration(hours: 3)) return;
    _lastCheck = now;
    checkForUpdates(context);
  }

  void goTab(int i) {
    if (i == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = i);
  }

  static const _items = [
    (Icons.home_rounded, 'الرئيسية'),
    (Icons.menu_book_rounded, 'الحفظ'),
    (Icons.mic_rounded, 'التجويد'),
    (Icons.local_library_rounded, 'المكتبة'),
    (Icons.emoji_events_rounded, 'المسابقات'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(key: ValueKey('home'), onTab: goTab),
      SurahListScreen(key: ValueKey('hifz')),
      TajweedScreen(key: ValueKey('tajweed')),
      LibraryScreen(key: ValueKey('library')),
      ArenaScreen(key: ValueKey('arena')),
    ];
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            transitionBuilder: (child, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: Offset(0, 0.02), end: Offset.zero).animate(a),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
          ),
        ),
        bottomNavigationBar: Container(
          margin: EdgeInsets.fromLTRB(12, 0, 12, 10),
          decoration: BoxDecoration(
            color: C.nav.withOpacity(0.97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.dark ? C.line : Colors.transparent),
            boxShadow: [BoxShadow(color: C.dark ? Color(0x66000000) : Color(0x22223A4A), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 66,
              child: Row(children: [for (var i = 0; i < _items.length; i++) _item(i)]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(int i) {
    final on = _tab == i;
    final c = on ? C.navActive : C.navIdle;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => goTab(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: on ? 16 : 8, vertical: 4),
            decoration: BoxDecoration(color: on ? C.navPill : Colors.transparent, borderRadius: BorderRadius.circular(14)),
            child: Icon(_items[i].$1, color: c, size: 24),
          ),
          SizedBox(height: 3),
          Text(_items[i].$2, style: TextStyle(fontSize: 10.5, color: c, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
