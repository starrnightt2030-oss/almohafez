import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/updater.dart';

/// بيدوّر على تحديث، ولو لقى نسخة أحدث يعرض نافذة التحديث.
/// manual = المستخدم ضغط «البحث عن تحديث» بنفسه (نقوله النتيجة حتى لو مفيش تحديث، ومانعملش اعتبار لـ «لاحقًا»)
Future<void> checkForUpdates(BuildContext context, {bool manual = false}) async {
  final u = await Updater.check();
  if (!context.mounted) return;
  if (u == null) {
    if (manual) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('عندك أحدث نسخة (${Updater.current})')));
    }
    return;
  }
  if (!manual && await Updater.snoozed(u.version)) return;
  if (!context.mounted) return;
  await showDialog(context: context, barrierDismissible: false, builder: (_) => UpdateDialog(info: u));
}

enum _St { info, downloading, installing, failed }

class UpdateDialog extends StatefulWidget {
  final UpdateInfo info;
  const UpdateDialog({super.key, required this.info});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _St st = _St.info;
  double f = 0;
  int got = 0, total = 0;
  File? file;
  String err = '';

  String mb(int b) => (b / 1048576).toStringAsFixed(1);

  Future<void> _start() async {
    setState(() { st = _St.downloading; f = 0; err = ''; });
    try {
      file ??= await Updater.download(widget.info, (x, g, t) {
        if (mounted) setState(() { f = x; got = g; total = t; });
      });
      await _install();
    } catch (e) {
      if (mounted) setState(() { st = _St.failed; err = 'التحميل اتقطع — اتأكد من النت وحاول تاني'; });
    }
  }

  Future<void> _install() async {
    setState(() => st = _St.installing);
    final ok = await Updater.install(file!);
    if (!ok && mounted) setState(() { st = _St.failed; err = 'ماقدرناش نفتح شاشة التثبيت — اسمح للتطبيق بتثبيت التحديثات من الإعدادات وحاول تاني'; });
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.info;
    return PopScope(
      canPop: st != _St.downloading,
      child: AlertDialog(
        backgroundColor: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: EdgeInsets.fromLTRB(22, 22, 22, 6),
        title: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.system_update_rounded, color: C.gold),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('تحديث جديد', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('النسخة ${u.version}${u.size > 0 ? ' • ${u.sizeMb} م.ب' : ''}', style: TextStyle(fontSize: 12.5, color: C.muted)),
            ]),
          ),
        ]),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (u.notes.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 240),
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الجديد في النسخة دي:', style: TextStyle(fontWeight: FontWeight.w600, color: C.gold)),
                    SizedBox(height: 6),
                    for (final n in u.notes)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Padding(padding: EdgeInsets.only(top: 7), child: Icon(Icons.circle, size: 6, color: C.gold)),
                          SizedBox(width: 8),
                          Expanded(child: Text(n, style: TextStyle(fontSize: 13.5, height: 1.6))),
                        ]),
                      ),
                  ]),
                ),
              )
            else
              Text('فيه نسخة أحدث من المحفظ. حدّث دلوقتي عشان تاخد آخر التحسينات.', style: TextStyle(height: 1.7)),
            if (st == _St.downloading || st == _St.installing) ...[
              SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: st == _St.installing ? 1 : (f > 0 ? f : null),
                  minHeight: 10,
                  backgroundColor: C.surface2,
                  color: C.gold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                st == _St.installing
                    ? 'اكتمل التحميل — اضغط «تثبيت» في الشاشة اللي ظهرت'
                    : total > 0
                        ? 'جاري التحميل ${(f * 100).round()}٪ • ${mb(got)} من ${mb(total)} م.ب'
                        : 'جاري التحميل…',
                style: TextStyle(fontSize: 12.5, color: C.muted),
              ),
            ],
            if (st == _St.failed) ...[
              SizedBox(height: 12),
              Text(err, style: TextStyle(color: C.red, fontSize: 13, height: 1.6)),
            ],
          ]),
        ),
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          if (st == _St.info) ...[
            TextButton(
              onPressed: () { Updater.snooze(u.version); Navigator.pop(context); },
              child: Text('لاحقًا'),
            ),
            FilledButton.icon(onPressed: _start, icon: Icon(Icons.download_rounded), label: Text('حدّث الآن')),
          ],
          if (st == _St.installing) ...[
            TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق')),
            FilledButton.icon(onPressed: _install, icon: Icon(Icons.install_mobile_rounded), label: Text('تثبيت')),
          ],
          if (st == _St.failed) ...[
            TextButton(onPressed: () => Navigator.pop(context), child: Text('إغلاق')),
            FilledButton.icon(onPressed: file != null ? _install : _start, icon: Icon(Icons.refresh_rounded), label: Text('حاول تاني')),
          ],
        ],
      ),
    );
  }
}
