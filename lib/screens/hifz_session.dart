import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../data/reciters.dart';
import '../logic/matcher.dart';
import '../services/audio.dart';
import '../services/speech.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import '../services/voice.dart';
import '../widgets/tajweed_text.dart';
import 'test_screen.dart';

enum Phase { idle, sheikh, user, checking, result }

/// جلسة الحفظ: الشيخ يقرأ الآية، ثم تردّد أنت، ويصحح لك حتى تتقنها.
class HifzSession extends StatefulWidget {
  final int surah;
  final int startAyah;
  /// تسميع آية واحدة فقط (من دروس التجويد).
  final bool single;
  const HifzSession({super.key, required this.surah, required this.startAyah, this.single = false});

  @override
  State<HifzSession> createState() => _HifzSessionState();
}

class _HifzSessionState extends State<HifzSession> {
  late int _a = widget.startAyah;
  Phase _phase = Phase.idle;
  String _heard = '';
  MatchResult? _result;
  int _attempt = 0;
  int _run = 0;
  int _repeat = 1;
  double _speed = 1.0;
  bool _hideText = false;
  bool _autoRepeat = true;
  int _countdown = 0;
  Timer? _timer;
  int _passed = 0;
  final _confetti = ConfettiController(duration: Duration(milliseconds: 1200));
  bool _tjReady = TajweedData.ready;

  Surah get _su => QuranData.surah(widget.surah);
  AyahRef get _ref => AyahRef(widget.surah, _a);
  String get _reciter => Progress.reciter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!widget.single) await Voice.cue('session_start');
      if (mounted) _runAyah();
    });
    if (!_tjReady) {
      TajweedData.load().then((_) {
        if (mounted) setState(() => _tjReady = true);
      });
    }
  }

  @override
  void dispose() {
    _run++;
    _timer?.cancel();
    Sheikh.stop();
    Ear.cancel();
    Voice.stop();
    _confetti.dispose();
    super.dispose();
  }

  void _cancelCountdown() {
    _timer?.cancel();
    _timer = null;
    _countdown = 0;
  }

  Future<void> _runAyah() async {
    final run = ++_run;
    _cancelCountdown();
    await Ear.cancel();
    await Voice.stop();
    setState(() {
      _phase = Phase.sheikh;
      _result = null;
      _heard = '';
    });
    Progress.setLast(_ref);
    for (var i = 0; i < _repeat; i++) {
      try {
        await Sheikh.play(_reciter, widget.surah, _a, speed: _speed);
      } catch (_) {
        if (!mounted || run != _run) return;
        setState(() => _phase = Phase.idle);
        toast(context, 'تعذّر تشغيل صوت الشيخ. تأكد من الإنترنت وارفع صوت الوسائط، ثم اضغط «استمع للشيخ».');
        return;
      }
      if (!mounted || run != _run) return;
    }
    await _listen(run);
  }

  Future<void> _listen([int? runId]) async {
    final run = runId ?? ++_run;
    _cancelCountdown();
    await Sheikh.stop();
    await Voice.stop();
    if (_attempt == 0 && runId != null) {
      await Voice.yourTurn();
      if (!mounted || run != _run) return;
    }
    final ok = await Ear.init();
    if (!mounted || run != _run) return;
    if (!ok) {
      setState(() => _phase = Phase.idle);
      toast(context, 'اسمح للتطبيق باستخدام الميكروفون، وتأكد من وجود خدمة التعرف على الصوت من Google.');
      return;
    }
    setState(() {
      _phase = Phase.user;
      _heard = '';
      _result = null;
    });
    try {
      await Ear.listen(
        onText: (t) {
          if (mounted && run == _run) setState(() => _heard = t);
        },
        onDone: (t) {
          if (mounted && run == _run) _evaluate(t, run);
        },
      );
    } catch (_) {
      if (mounted && run == _run) setState(() => _phase = Phase.idle);
    }
  }

  void _evaluate(String heard, int run) {
    final res = Matcher.match(QuranData.simpleWords(_ref), heard);
    Progress.touchToday();
    setState(() {
      _heard = heard;
      _result = res;
      _phase = Phase.result;
      _attempt++;
    });
    if (heard.trim().isEmpty) {
      Voice.cue('no_voice');
      toast(context, 'لم أسمع صوتك. اضغط الميكروفون واقرأ الآية.');
      return;
    }
    if (res.perfect) {
      HapticFeedback.mediumImpact();
      _confetti.play();
      if (!Progress.isMem(_ref)) Progress.addXp(10);
      Progress.markMem(_ref);
      if (widget.single) Progress.markPracticed(_ref);
      _passed++;
      () async {
        await Voice.wellDone();
        await Future.delayed(Duration(milliseconds: 400));
        if (!mounted || run != _run) return;
        if (widget.single) {
          setState(() => _phase = Phase.idle);
        } else {
          _next();
        }
      }();
    } else {
      HapticFeedback.heavyImpact();
      () async {
        if (Voice.hasCue('recite_wrong')) {
          final onlyMissing = res.words.every((w) => w.state != WordState.wrong);
          await Voice.cue(onlyMissing ? 'recite_missing' : 'recite_wrong');
          if (mounted && run == _run && _autoRepeat) await Voice.cue('sheikh_repeat');
        } else {
          await Voice.say(_feedbackSpeech(res));
        }
        if (!mounted || run != _run || !_autoRepeat) return;
        _countdown = 4;
        setState(() {});
        _timer = Timer.periodic(Duration(seconds: 1), (t) {
          if (!mounted || run != _run) {
            t.cancel();
            return;
          }
          setState(() => _countdown--);
          if (_countdown <= 0) {
            t.cancel();
            _runAyah();
          }
        });
      }();
    }
  }

  /// توجيه صوتي يشرح الأخطاء وما يجب فعله.
  String _feedbackSpeech(MatchResult res) {
    final sw = QuranData.simpleWords(_ref);
    final parts = <String>[];
    for (var i = 0; i < res.words.length && parts.length < 2; i++) {
      final w = res.words[i];
      if (w.state == WordState.missing) parts.add('نسيت كلمة ${sw[i]}');
      if (w.state == WordState.wrong) parts.add('قرأت ${w.heard} والصحيح ${sw[i]}');
    }
    final more = res.errors > parts.length ? ' وأخطاء أخرى على الشاشة' : '';
    final tail = _autoRepeat ? '. استمع للشيخ جيدًا ثم أعد القراءة' : '. راجع الكلمات الحمراء ثم حاول مرة أخرى';
    return 'انتبه، ${parts.join('، و')}$more$tail';
  }

  void _next() {
    if (widget.single) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_a >= _su.count) {
      _finish();
      return;
    }
    setState(() {
      _a++;
      _attempt = 0;
    });
    _runAyah();
  }

  void _prev() {
    if (_a <= 1) return;
    setState(() {
      _a--;
      _attempt = 0;
    });
    _runAyah();
  }

  Future<void> _finish() async {
    _run++;
    await Sheikh.stop();
    if (!mounted) return;
    Voice.cue('surah_done');
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.surface,
        title: Text('ما شاء الله، أتممت السورة'),
        content: Text('أتقنت ${ar(_passed)} آية في هذه الجلسة. هل تريد اختبار حفظك لسورة ${_su.name} الآن؟',
            style: TextStyle(height: 1.7, color: C.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('لاحقًا')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text('اختبرني')),
        ],
      ),
    );
    if (!mounted) return;
    if (go == true) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TestScreen.surah(widget.surah)));
    } else {
      Navigator.of(context).pop();
    }
  }

  void _settings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        void upd(VoidCallback f) {
          setS(f);
          setState(() {});
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 20 + MediaQuery.of(ctx).padding.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('إعدادات الجلسة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            SizedBox(height: 16),
            Text('عدد مرات قراءة الشيخ للآية', style: TextStyle(color: C.muted, fontSize: 13)),
            SizedBox(height: 8),
            Row(children: [
              for (final n in [1, 2, 3, 5])
                Padding(
                  padding: EdgeInsetsDirectional.only(end: 8),
                  child: ChoiceChip(
                    label: Text(ar(n)),
                    selected: _repeat == n,
                    onSelected: (_) => upd(() => _repeat = n),
                    selectedColor: C.gold,
                    labelStyle: TextStyle(color: _repeat == n ? C.onGold : C.text),
                    backgroundColor: C.deep,
                  ),
                ),
            ]),
            SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _hideText,
              activeColor: C.gold,
              onChanged: (v) => upd(() => _hideText = v),
              title: Text('إخفاء الآية أثناء قراءتي', style: TextStyle(fontSize: 14.5)),
              subtitle: Text('للتسميع من الحفظ', style: TextStyle(fontSize: 12, color: C.muted)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _autoRepeat,
              activeColor: C.gold,
              onChanged: (v) => upd(() => _autoRepeat = v),
              title: Text('الشيخ يعيد الآية تلقائيًا عند الخطأ', style: TextStyle(fontSize: 14.5)),
            ),
          ]),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final words = QuranData.displayWords(_ref);
    final hide = _hideText && (_phase == Phase.user);
    final r = _result;
    final errors = <Widget>[];
    if (r != null && _heard.trim().isNotEmpty) {
      for (var i = 0; i < words.length; i++) {
        final w = r.words[i];
        if (w.state == WordState.wrong || w.state == WordState.missing) {
          errors.add(_errorNote(words[i], Matcher.note(QuranData.simpleWords(_ref)[i], w)));
        }
      }
    }
    return AppBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(children: [
          Text('سورة ${_su.name}'),
          Text('الآية ${ar(_a)} من ${ar(_su.count)}', style: TextStyle(fontSize: 12, color: C.muted)),
        ]),
        actions: [IconButton(onPressed: _settings, icon: Icon(Icons.tune), tooltip: 'الإعدادات')],
      ),
      body: SafeArea(
        child: Stack(children: [
        Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: _sheikhCard(),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.fromLTRB(20, 14, 20, 0),
              decoration: BoxDecoration(
                color: C.deep,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: C.line),
              ),
              child: ListView(
                padding: EdgeInsets.all(18),
                children: [
                  if (_a > 1)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text(QuranData.uthmaniText(AyahRef(widget.surah, _a - 1)) + ' ۝${ar(_a - 1)}',
                          textAlign: TextAlign.center,
                          style: quranStyle.copyWith(fontSize: 19, color: C.muted)),
                    ),
                  if (hide)
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Text('الآية مخفية… اقرأ من حفظك', style: TextStyle(color: C.muted)),
                    )
                  else
                    TajweedAyahView(
                        key: ValueKey('${widget.surah}:$_a:$_tjReady'),
                        ref: _ref,
                        result: _heard.trim().isEmpty ? null : r,
                        fontSize: 27),
                  if (!hide && _result == null) ...[SizedBox(height: 10), TajweedLegend()],
                  if (errors.isNotEmpty) ...[SizedBox(height: 10), ...errors],
                  if (_phase == Phase.user && _heard.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Text('أسمع: $_heard',
                        textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 13, height: 1.7)),
                  ],
                ],
              ),
            ),
          ),
          _controls(),
        ]),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 18,
            colors: [C.gold, C.green, C.blue],
          ),
        ),
        ]),
      ),
    ),
    );
  }

  Widget _sheikhCard() {
    final rc = reciterById(_reciter);
    String status;
    Color sc = C.green;
    switch (_phase) {
      case Phase.sheikh:
        status = _attempt > 0 ? 'الشيخ يعيد الآية — استمع جيدًا' : 'الشيخ يقرأ الآية — استمع';
        break;
      case Phase.user:
        status = 'دورك الآن — اقرأ الآية كاملة';
        sc = C.gold;
        break;
      case Phase.result:
        if (_result != null && _result!.perfect && _heard.trim().isNotEmpty) {
          status = 'أحسنت! قراءة صحيحة';
        } else if (_countdown > 0) {
          status = 'الشيخ سيعيد الآية خلال ${ar(_countdown)}';
          sc = C.red;
        } else {
          status = 'راجع الأخطاء ثم حاول مرة أخرى';
          sc = C.red;
        }
        break;
      default:
        status = 'اضغط تشغيل لتبدأ';
        sc = C.muted;
    }
    return Panel(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 18,
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.greenSoft, border: Border.all(color: sc, width: 2)),
          child: Icon(_phase == Phase.user ? Icons.mic : Icons.volume_up_outlined, color: sc, size: 22),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('الشيخ ${rc.name}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 2),
            Text(status, style: TextStyle(fontSize: 12.5, color: sc)),
          ]),
        ),
        if (_attempt > 0) Tag('المحاولة ${ar(_attempt)}'),
      ]),
    );
  }

  Widget _errorNote(String word, String note) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: C.redSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.redLine)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(word, style: quranStyle.copyWith(fontSize: 18, color: C.red, height: 1.5)),
        SizedBox(width: 10),
        Expanded(
            child: Text(note, style: TextStyle(fontSize: 12.5, height: 1.7, color: C.text))),
      ]),
    );
  }

  Widget _controls() {
    final listening = _phase == Phase.user;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _round(Icons.skip_next_rounded, 'الآية السابقة', _a > 1 ? _prev : null),
          _round(Icons.replay_rounded, 'استمع للشيخ مرة أخرى', _runAyah),
          GestureDetector(
            onTap: () {
              if (listening) {
                Ear.stop();
              } else {
                _listen();
              }
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 250),
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: listening ? C.green : C.gold,
                boxShadow: [
                  BoxShadow(color: (listening ? C.green : C.gold).withOpacity(0.35), blurRadius: listening ? 26 : 10, spreadRadius: listening ? 6 : 0),
                ],
              ),
              child: Icon(listening ? Icons.stop_rounded : Icons.mic_rounded, size: 36, color: C.bg),
            ),
          ),
          _round(null, 'سرعة التلاوة', () {
            setState(() => _speed = _speed == 1.0 ? 0.75 : (_speed == 0.75 ? 1.25 : 1.0));
          }, label: '${ar(_speed.toString().replaceAll('.0', ''))}×'),
          _round(Icons.skip_previous_rounded, 'الآية التالية', _a < _su.count ? _next : _finish),
        ]),
        SizedBox(height: 10),
        Text(
          listening ? 'أستمع إليك… اضغط للإنهاء عند الانتهاء' : 'اضغط الميكروفون لتقرأ مباشرة',
          style: TextStyle(fontSize: 12.5, color: C.muted),
        ),
      ]),
    );
  }

  Widget _round(IconData? icon, String tip, VoidCallback? onTap, {String? label}) {
    return Tooltip(
      message: tip,
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: C.surface, border: Border.all(color: C.line)),
          child: label != null
              ? Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))
              : Icon(icon, color: onTap == null ? C.line2 : C.text, size: 24),
        ),
      ),
    );
  }
}
