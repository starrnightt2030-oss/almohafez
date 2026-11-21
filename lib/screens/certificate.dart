import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../data/quran.dart';
import '../data/progress.dart';
import '../widgets/certificate_art.dart';
import '../services/voice.dart';

String gradeOf(int pct) {
  if (pct >= 95) return 'ممتاز';
  if (pct >= 85) return 'جيد جدًا';
  if (pct >= 75) return 'جيد';
  return 'يحتاج مراجعة';
}

String _today() {
  const months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  final d = DateTime.now();
  return '${ar(d.day)} ${months[d.month - 1]} ${ar(d.year)}';
}

String _code() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final r = math.Random();
  String part(int n) => List.generate(n, (_) => chars[r.nextInt(chars.length)]).join();
  return 'MHZ-${part(4)}-${part(3)}';
}

Future<String?> askName(BuildContext context) async {
  final existing = Progress.name;
  if (existing != null && existing.isNotEmpty) return existing;
  final ctrl = TextEditingController();
  final v = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: C.surface,
      title: Text('اسمك على الشهادة'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: 'اكتب اسمك كما تريد أن يظهر'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text('حفظ')),
      ],
    ),
  );
  if (v == null || v.isEmpty) return null;
  await Progress.setName(v);
  return v;
}

Future<void> issueSurahCertificate(BuildContext context, int surah, int testPct) async {
  final name = await askName(context);
  if (name == null || !context.mounted) return;
  final su = QuranData.surah(surah);
  final memPct = (Progress.memInSurah(surah) * 100 / su.count).round();
  final cert = Cert('surah', 'سورة ${su.name}', name, testPct, memPct, gradeOf(testPct), _today(), _code());
  await Progress.addCert(cert);
  if (!context.mounted) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateView(cert: cert)));
}

Future<void> issueCertificate(BuildContext context, String kind, String title, int pct) async {
  final name = await askName(context);
  if (name == null || !context.mounted) return;
  final cert = Cert(kind, title, name, pct, pct, gradeOf(pct), _today(), _code());
  await Progress.addCert(cert);
  if (!context.mounted) return;
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateView(cert: cert)));
}

class CertificateView extends StatefulWidget {
  final Cert cert;
  const CertificateView({super.key, required this.cert});

  @override
  State<CertificateView> createState() => _CertificateViewState();
}

class _CertificateViewState extends State<CertificateView> {
  final _key = GlobalKey();
  bool _busy = false;
  late int _style = widget.cert.kind == 'surah' ? 0 : 1;

  @override
  void initState() {
    super.initState();
    Voice.cue('certificate');
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/almohafez_${widget.cert.code}.png');
      await f.writeAsBytes(data!.buffer.asUint8List());
      await Share.shareXFiles([XFile(f.path)], text: 'شهادتي من تطبيق المحفظ — ${widget.cert.title}');
    } catch (_) {
      if (mounted) toast(context, 'تعذّرت مشاركة الشهادة');
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'شهادتك',
      body: ListView(padding: EdgeInsets.all(16), children: [
        Text('ما شاء الله، تبارك الله', textAlign: TextAlign.center, style: TextStyle(color: C.green, fontSize: 15, fontWeight: FontWeight.w600)),
        SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: RepaintBoundary(key: _key, child: CertificateArt(cert: widget.cert, style: _style)),
          ),
        ).enter(0),
        SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final e in [(0, 'كلاسيكي'), (1, 'القوس')])
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: ChoiceChip(
                label: Text(e.$2),
                selected: _style == e.$1,
                onSelected: (_) => setState(() => _style = e.$1),
                selectedColor: C.gold,
                labelStyle: TextStyle(color: _style == e.$1 ? C.onGold : C.text),
                backgroundColor: C.surface,
              ),
            ),
        ]),
        SizedBox(height: 8),
        Text('أدِر الموبايل أو كبّر الصورة بعد المشاركة لرؤية التفاصيل.\nهذه شهادة تشجيعية من التطبيق، وليست إجازة بالسند.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: C.muted, height: 1.6)),
        SizedBox(height: 16),
        GoldButton(
          label: _busy ? 'جارٍ التجهيز…' : 'مشاركة الشهادة (صورة عالية الدقة)',
          icon: Icons.share_rounded,
          onPressed: _busy ? null : _share,
        ),
      ]),
    );
  }
}

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = Progress.certs.reversed.toList();
    return AppPage(
      title: 'شهاداتي',
      body: list.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('لا توجد شهادات بعد.\nأتمّ حفظ سورة واجتز اختبارها لتحصل على أول شهادة.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.8)),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = list[i];
                return Panel(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateView(cert: c))),
                  child: Row(children: [
                    IconBox(icon: Icons.workspace_premium_outlined, color: C.gold, bg: C.goldSoft),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: TextStyle(fontWeight: FontWeight.w600)),
                        SizedBox(height: 2),
                        Text('${c.grade} · ${c.date}', style: TextStyle(fontSize: 12, color: C.muted)),
                      ]),
                    ),
                    Icon(Icons.chevron_left, color: C.muted),
                  ]),
                );
              },
            ),
    );
  }
}
