import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme.dart';
import 'data/quran.dart';
import 'data/progress.dart';
import 'screens/home.dart';
import 'screens/surah_list.dart';
import 'screens/tajweed.dart';
import 'screens/library.dart';
import 'screens/groups.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: C.nav,
  ));
  await Future.wait([QuranData.load(), Progress.load()]);
  runApp(const MohafezApp());
}

class MohafezApp extends StatelessWidget {
  const MohafezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المحفظ',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  static final GlobalKey<ShellState> shellKey = GlobalKey<ShellState>();

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int _tab = 0;

  void go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(onTab: go),
      const SurahListScreen(),
      const TajweedScreen(),
      const LibraryScreen(),
      const GroupsScreen(),
    ];
    return Scaffold(
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: C.nav, border: Border(top: BorderSide(color: Color(0xFF1E3A31)))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(children: [
              _item(0, Icons.home_outlined, 'الرئيسية'),
              _item(1, Icons.menu_book_outlined, 'الحفظ'),
              _item(2, Icons.mic_none_rounded, 'التجويد'),
              _item(3, Icons.auto_stories_outlined, 'العلم'),
              _item(4, Icons.groups_outlined, 'المجموعات'),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _item(int i, IconData icon, String label) {
    final on = _tab == i;
    final c = on ? C.gold : C.muted;
    return Expanded(
      child: InkWell(
        onTap: () => go(i),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: c, size: 24),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
        ]),
      ),
    );
  }
}
