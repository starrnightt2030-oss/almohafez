import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme.dart';
import '../data/progress.dart';
import '../services/backup.dart';

/// يعرض كود النسخة الاحتياطية مع نسخ ومشاركة.
Future<void> showBackupCode(BuildContext context, String code) => showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('كود النسخة الاحتياطية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('احتفظ بالكود ده في مكان آمن. لو غيّرت موبايلك أو مسحت التطبيق، اكتبه وكل تقدّمك يرجع.',
              style: TextStyle(color: C.muted, height: 1.7, fontSize: 13)),
          SizedBox(height: 14),
          SelectableText(Backup.pretty(code),
              textDirection: TextDirection.ltr, style: TextStyle(fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w700, color: C.gold)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: Backup.pretty(code)));
              toast(ctx, 'تم نسخ الكود');
            },
            child: Text('نسخ'),
          ),
          TextButton(
            onPressed: () => Share.share('كود النسخة الاحتياطية لتطبيق سَنَد (لا تشاركه مع أحد): ${Backup.pretty(code)}'),
            child: Text('حفظ/مشاركة'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('تم')),
        ],
      ),
    );

/// استرجاع من كود: بيرجع true لو اتسترجع (والتطبيق بيتعاد بناؤه).
Future<bool> showRestoreDialog(BuildContext context) async {
  final c = TextEditingController();
  final code = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('استرجاع نسخة احتياطية'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('اكتب الكود (١٢ حرف). التقدّم الحالي على الموبايل ده هيتستبدل بالنسخة.', style: TextStyle(color: C.muted, fontSize: 13, height: 1.6)),
        SizedBox(height: 10),
        TextField(
          controller: c,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(fontSize: 18, letterSpacing: 2),
          decoration: InputDecoration(hintText: 'XXXX-XXXX-XXXX'),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء')),
        TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: Text('استرجاع')),
      ],
    ),
  );
  if (code == null || code.trim().isEmpty || !context.mounted) return false;
  final r = await Backup.restore(code);
  if (!context.mounted) return false;
  if (r == true) {
    toast(context, 'تم استرجاع تقدّمك بالكامل');
    Progress.themeNotifier.value = Progress.themeIndex;
    Progress.reloadTick.value++;
    return true;
  }
  toast(context, r == false ? 'الكود غير صحيح' : 'تعذّر الاتصال، تأكد من الإنترنت');
  return false;
}
