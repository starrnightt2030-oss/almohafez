import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'data/quran.dart';
import 'data/progress.dart';
import 'data/course.dart';
import 'services/voice.dart';
import 'services/audio.dart';
import 'data/voice_lines.dart';
import 'services/quran_ear.dart';
import 'services/reminders.dart';
import 'services/voice_pack.dart';
import 'services/backup.dart';
import 'widgets/backup_dialogs.dart';
import 'screens/weekly_report.dart';
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
    Progress.reloadTick.addListener(_onTheme);
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
      key: ValueKey('${C.t.id}-${Progress.reloadTick.value}'),
      title: 'سَنَد',
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

/// ألوان الهوية (ثابتة في البداية والمقدمة مهما كان الثيم)
const _brandTop = Color(0xFF173F37);
const _brandMid = Color(0xFF0B2722);
const _brandBottom = Color(0xFF06171A);
const _brandGold = Color(0xFFE7C77B);
const _brandGoldLight = Color(0xFFF2D68E);
const _brandText = Color(0xFFF5EBD3);

/// شاشة البداية: شعار سَنَد مع توهّج ذهبي أثناء تحميل البيانات.
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage(kEmblem), context);
  }

  Future<void> _boot() async {
    final t = Future.delayed(Duration(milliseconds: 1900));
    await Future.wait([QuranData.load(), Courses.load()]);
    _booted = true;
    Voice.init();
    TajweedData.load();
    await t;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 700),
      pageBuilder: (_, __, ___) => Progress.introSeen ? Shell() : IntroScreen(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.15), radius: 1.0, colors: [_brandTop, _brandMid, _brandBottom], stops: [0, 0.55, 1]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: _brandGold, opacity: 0.06))),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [_brandGold.withOpacity(0.24), _brandGold.withOpacity(0)]),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: Offset(0.9, 0.9), end: Offset(1.05, 1.05), duration: 1800.ms, curve: Curves.easeInOut),
                Image.asset(kEmblem, width: 250, height: 250, filterQuality: FilterQuality.high)
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: Offset(0.82, 0.82), duration: 900.ms, curve: Curves.easeOutBack)
                    .then()
                    .shimmer(duration: 1200.ms, color: Color(0x66FFF3CF)),
              ]),
              SizedBox(height: 8),
              Container(width: 60, height: 1, color: _brandGold.withOpacity(0.6)).animate().fadeIn(delay: 500.ms).scaleX(begin: 0, end: 1, duration: 600.ms),
              SizedBox(height: 12),
              Text('معلّمك الشخصي للقرآن الكريم', style: TextStyle(fontFamily: 'Amiri', fontSize: 20, color: _brandGoldLight))
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
            ]),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: SafeArea(
              top: false,
              child: Column(children: [
                Text('تطوير', style: TextStyle(fontSize: 11, color: Color(0xFF8FA79C))),
                SizedBox(height: 2),
                Text(kDeveloper, textDirection: TextDirection.ltr, style: TextStyle(fontSize: 13, color: _brandGold, letterSpacing: 1)),
              ]).animate().fadeIn(delay: 900.ms, duration: 600.ms),
            ),
          ),
        ]),
      ),
    );
  }
}

/// المقدمة: ٣ صفحات تعريفية تظهر أول مرة بس.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pc = PageController();
  int _i = 0;

  static const _pages = [
    (Icons.record_voice_over_rounded, 'اقرأ على شيخك', 'في أي وقت، وبكل دقة',
        'يتلو الشيخ الآية، فتردّد خلفه دون أن تلمس الشاشة، ونصحّح لك الكلمة والحركة لحظة بلحظة.'),
    (Icons.auto_stories_rounded, 'أتقن التجويد', 'خطوة بخطوة حتى الإتقان',
        'أكاديمية كاملة بدروس صوتية وأمثلة بصوت الشيخ واختبار بعد كل درس، وشهادة عند كل باب.'),
    (Icons.local_library_rounded, 'تفقّه في دينك', 'من مصادر موثوقة',
        'مكتبة في العقيدة والفقه والسيرة والأسرة والمعاملات، وأحاديث مختارة مع شرحها واختبارات للفهم.'),
  ];

  bool _muted = false;
  int _voiceRun = 0;

  @override
  void initState() {
    super.initState();
    // الافتتاح: ﴿وَرَتِّلِ ٱلْقُرْآنَ تَرْتِيلًا﴾ بصوت الشيخ، ثم صوت المعلّم مع كل صفحة
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final run = ++_voiceRun;
      try {
        await Sheikh.play(Progress.reciter, 73, 4).timeout(Duration(seconds: 12));
      } catch (_) {}
      if (!mounted || run != _voiceRun || _muted) return;
      _speak(0);
    });
  }

  void _speak(int i) {
    if (_muted) return;
    final lines = voiceLines['intro'] ?? const [];
    if (i >= lines.length) return;
    Voice.say(lines[i], clip: 'assets/audio/voice/intro_${i + 1}', force: true);
  }

  @override
  void dispose() {
    _voiceRun++;
    Sheikh.stop();
    Voice.stop();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    _voiceRun++;
    Sheikh.stop();
    Voice.stop();
    await Progress.setIntroSeen();
    await Progress.markGreeted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) => Shell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  void _next() {
    if (_i < _pages.length - 1) {
      _pc.nextPage(duration: Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_brandMid, Color(0xFF0E3A31), Color(0xFF08201C)]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: StarPatternPainter(color: _brandGold, opacity: 0.05))),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(children: [
                  Image.asset(kEmblem, width: 54, height: 54),
                  Spacer(),
                  IconButton(
                    tooltip: _muted ? 'تشغيل الصوت' : 'كتم الصوت',
                    icon: Icon(_muted ? Icons.volume_off_rounded : Icons.volume_up_rounded, color: Color(0xFFC9B88F)),
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      if (_muted) {
                        _voiceRun++;
                        Sheikh.stop();
                        Voice.stop();
                      } else {
                        _speak(_i);
                      }
                    },
                  ),
                  TextButton(onPressed: _finish, child: Text('تخطّي', style: TextStyle(color: Color(0xFFC9B88F)))),
                ]),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    setState(() => _i = i);
                    _voiceRun++;
                    Sheikh.stop();
                    _speak(i);
                  },
                  itemBuilder: (_, i) => _page(i),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (var k = 0; k < _pages.length; k++)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 3),
                        width: k == _i ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: k == _i ? _brandGold : _brandGold.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ]),
                  SizedBox(height: 20),
                  Pressable(
                    onTap: _next,
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8E3A3), Color(0xFFD3AE5C)]),
                        boxShadow: [BoxShadow(color: Color(0x59D3AE5C), blurRadius: 30, offset: Offset(0, 12))],
                      ),
                      alignment: Alignment.center,
                      child: Text(_i == _pages.length - 1 ? 'ابدأ رحلتك' : 'التالي',
                          style: TextStyle(color: Color(0xFF2A1E07), fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (await showRestoreDialog(context)) _finish();
                    },
                    child: Text('عندي كود نسخة احتياطية', style: TextStyle(color: Color(0xFFC9B88F), fontSize: 13)),
                  ),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _page(int i) {
    final p = _pages[i];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Center(
            child: Stack(alignment: Alignment.center, children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0xE62E7A63), Color(0x000E3A31)]),
                ),
              ),
              Container(
                width: 190,
                height: 230,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(95), bottom: Radius.circular(18)),
                  border: Border.all(color: _brandGold.withOpacity(0.7), width: 1.6),
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x332B7A60), Color(0x000E3A31)]),
                ),
              ),
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8E3A3), Color(0xFFC99A42)]),
                  boxShadow: [BoxShadow(color: Color(0x66E7C77B), blurRadius: 40)],
                ),
                child: Icon(p.$1, size: 50, color: Color(0xFF2A1E07)),
              ).animate(key: ValueKey(i)).scale(begin: Offset(0.7, 0.7), duration: 600.ms, curve: Curves.easeOutBack),
            ]),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), border: Border.all(color: _brandGold.withOpacity(0.4))),
          child: Text('${ar(i + 1)} / ${ar(_pages.length)}', style: TextStyle(fontSize: 11.5, color: _brandGold)),
        ),
        SizedBox(height: 14),
        Text(p.$2, style: TextStyle(fontFamily: 'Amiri', fontSize: 34, fontWeight: FontWeight.w700, color: _brandText, height: 1.3)),
        Text(p.$3, style: TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.w700, color: _brandGoldLight, height: 1.3)),
        SizedBox(height: 12),
        Text(p.$4, style: TextStyle(fontSize: 14, color: Color(0xFFBFCDBF), height: 1.9)),
        SizedBox(height: 18),
      ]),
    );
  }
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
    // ترحيب صوتي قصير مرة في اليوم (صباح/مساء/أهلًا بعودتك)
    Future.delayed(Duration(milliseconds: 900), () async {
      if (!mounted || !Progress.greetOn || Progress.greetedToday || !Progress.introSeen) return;
      final away = Progress.wasAway;
      await Progress.markGreeted();
      final h = DateTime.now().hour;
      Voice.cue(away ? 'greet_back' : (h >= 4 && h < 12 ? 'greet_morning' : 'greet_evening'), force: true);
    });
    // التذكيرات: أول مرة نطلب الإذن، وبعدين نجدول، ولو اتفتح من إشعار التقرير نفتحه
    Future.delayed(Duration(seconds: 3), () async {
      await Reminders.init();
      if (!Progress.notifAsked) {
        await Progress.setNotifAsked();
        await Reminders.askPermission();
      }
      await Reminders.reschedule();
      if (Reminders.launchPayload == 'weekly' && mounted) {
        Reminders.launchPayload = null;
        Navigator.of(context).push(fadeRoute(WeeklyReportScreen()));
      }
    });
    // المصحِّح الذكي يتحمّل في الخلفية مرة واحدة (١٩ م.ب) عشان يبقى جاهز في الحفظ والاختبارات
    Future.delayed(Duration(seconds: 6), () async {
      if (Progress.smartEar && !await QuranEar.checkInstalled()) await QuranEar.download();
      // حزمة الصوت (شرح الدروس والأحاديث) — مرة واحدة، والجديد بس بعد كده
      await VoicePack.sync();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoCheck();
    // لما يخرج من التطبيق: نعيد جدولة التذكيرات (لو اتحفظ النهارده يتلغي تنبيه السلسلة)
    if (state == AppLifecycleState.paused) {
      Reminders.reschedule();
      Backup.auto();
    }
  }

  void _autoCheck() {
    if (!mounted || kStore) return;
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
    (Icons.emoji_events_rounded, 'إنجازاتي'),
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
            color: C.nav.withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: C.dark ? C.gold.withOpacity(0.3) : C.line),
            boxShadow: [BoxShadow(color: C.dark ? Color(0x66000000) : Color(0x22223A4A), blurRadius: 20, offset: Offset(0, 8))],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
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
        child: Center(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: on ? 12 : 4, vertical: 6),
            decoration: BoxDecoration(
              gradient: on ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: C.goldGrad) : null,
              borderRadius: BorderRadius.circular(16),
              boxShadow: on ? [BoxShadow(color: C.gold.withOpacity(0.3), blurRadius: 12, offset: Offset(0, 4))] : null,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(_items[i].$1, color: c, size: 22),
              SizedBox(height: 2),
              Text(_items[i].$2,
                  maxLines: 1,
                  style: TextStyle(fontSize: 10.5, color: c, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
            ]),
          ),
        ),
      ),
    );
  }
}
