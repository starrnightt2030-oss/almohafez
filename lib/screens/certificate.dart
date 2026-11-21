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
      title: const Text('اسمك على الشهادة'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'اكتب اسمك كما تريد أن يظهر'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('حفظ')),
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

Future<void> issueTajweedCertificate(BuildContext context, String levelTitle, int pct) async {
  final name = await askName(context);
  if (name == null || !context.mounted) return;
  final cert = Cert('tajweed', levelTitle, name, pct, pct, gradeOf(pct), _today(), _code());
  await Progress.addCert(cert);
  if (!context.mounted) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateView(cert: cert)));
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
    final c = widget.cert;
    final isSurah = c.kind == 'surah';
    return Scaffold(
      appBar: AppBar(title: const Text('شهادتك')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('ما شاء الله، تبارك الله', textAlign: TextAlign.center, style: TextStyle(color: C.green, fontSize: 14)),
          const SizedBox(height: 12),
          RepaintBoundary(
            key: _key,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFF7F1E1), borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB8923C), width: 1.5),
                ),
                child: Column(children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFB8923C), size: 36),
                  const SizedBox(height: 8),
                  const Text('تطبيق المحفظ', style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: Color(0xFF8A6A22))),
                  const SizedBox(height: 6),
                  Text(isSurah ? 'شهادة إتمام حفظ' : 'شهادة اجتياز مستوى',
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 30, fontWeight: FontWeight.w700, color: Color(0xFF1C3A2E))),
                  const SizedBox(height: 10),
                  const Text('يُشهد بأن', style: TextStyle(fontSize: 13, color: Color(0xFF4D5A53))),
                  const SizedBox(height: 4),
                  Text(c.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2A24))),
                  const SizedBox(height: 4),
                  Text(isSurah ? 'قد أتمّ حفظ وتسميع' : 'قد اجتاز بنجاح في أكاديمية التجويد',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF4D5A53))),
                  const SizedBox(height: 6),
                  Text(c.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: isSurah ? 'AmiriQuran' : 'Amiri',
                          fontSize: 26,
                          height: 1.8,
                          fontWeight: isSurah ? FontWeight.w400 : FontWeight.w700,
                          color: const Color(0xFF1C3A2E))),
                  const SizedBox(height: 12),
                  Row(children: [
                    _stat(isSurah ? 'الاختبار' : 'النتيجة', c.hifz),
                    const SizedBox(width: 8),
                    if (isSurah) ...[_stat('الآيات المتقنة', c.accuracy), const SizedBox(width: 8)],
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFEFE5CC), borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          Text(c.grade, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF8A6A22))),
                          const Text('التقدير', style: TextStyle(fontSize: 11, color: Color(0xFF4D5A53))),
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.date, style: const TextStyle(fontSize: 11.5, color: Color(0xFF4D5A53))),
                        Text('رمز الشهادة: ${c.code}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF4D5A53))),
                      ]),
                    ),
                    const Icon(Icons.verified_outlined, color: Color(0xFFB8923C), size: 34),
                  ]),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'هذه شهادة إتمام تشجيعية من التطبيق، وليست إجازة بالسند.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: C.muted),
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: _busy ? 'جارٍ التجهيز…' : 'مشاركة الشهادة',
            icon: Icons.share_outlined,
            onPressed: _busy ? null : _share,
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, int v) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFEFE5CC), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text('${ar(v)}٪', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1C3A2E))),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF4D5A53))),
          ]),
        ),
      );
}

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = Progress.certs.reversed.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('شهاداتي')),
      body: list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('لا توجد شهادات بعد.\nأتمّ حفظ سورة واجتز اختبارها لتحصل على أول شهادة.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.muted, height: 1.8)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = list[i];
                return Panel(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CertificateView(cert: c))),
                  child: Row(children: [
                    const IconBox(icon: Icons.workspace_premium_outlined, color: C.gold, bg: C.goldSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('${c.grade} · ${c.date}', style: const TextStyle(fontSize: 12, color: C.muted)),
                      ]),
                    ),
                    const Icon(Icons.chevron_left, color: C.muted),
                  ]),
                );
              },
            ),
    );
  }
}
