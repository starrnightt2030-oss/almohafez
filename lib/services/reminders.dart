import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../data/progress.dart';

/// التذكيرات: وِرد يومي في الميعاد اللي تختاره، وتنبيه لو السلسلة هتنقطع، وتقرير أسبوعي يوم الجمعة.
/// بنعيد الجدولة كل ما التطبيق يفتح، فلو الساعة اتغيرت (توقيت صيفي) بتتظبط لوحدها.
class Reminders {
  static final _n = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static String? launchPayload;

  static const _daily = 1, _streak = 2, _weekly = 3;

  static const _dailyTexts = [
    ('وِردك اليوم بانتظارك', 'دقائق مع كتاب الله تنير يومك. الشيخ جاهز، هيا نحفظ.'),
    ('حان وقت الوِرد', '«خيركم من تعلّم القرآن وعلّمه» — افتح سَنَد وابدأ.'),
    ('آية اليوم تنتظرك', 'خطوة صغيرة كل يوم توصلك لختم القرآن بإذن الله.'),
    ('لا تقطع صحبة القرآن', 'أحب الأعمال إلى الله أدومها وإن قلّ. وِردك جاهز.'),
  ];

  static NotificationDetails get _details => NotificationDetails(
        android: AndroidNotificationDetails(
          'wird',
          'تذكير الوِرد',
          channelDescription: 'تذكير يومي بوِرد الحفظ والمراجعة',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_stat_sanad',
        ),
      );

  static Future<void> init() async {
    if (_ready) return;
    try {
      tzdata.initializeTimeZones();
      await _n.initialize(
        settings: InitializationSettings(android: AndroidInitializationSettings('ic_stat_sanad')),
        onDidReceiveNotificationResponse: (r) => launchPayload = r.payload,
      );
      final launch = await _n.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) launchPayload = launch!.notificationResponse?.payload;
      _ready = true;
    } catch (_) {}
  }

  /// يطلب إذن الإشعارات (أندرويد ١٣+) — مرة واحدة.
  static Future<bool> askPermission() async {
    await init();
    try {
      final a = _n.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await a?.requestNotificationsPermission() ?? true;
    } catch (_) {
      return false;
    }
  }

  /// الوقت الجاي (بتوقيت الجهاز) محوّل لـ UTC للجدولة.
  static tz.TZDateTime _next(int hour, int minute, {int? weekday, bool todayOnly = false}) {
    final now = DateTime.now();
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (weekday != null) {
      while (t.weekday != weekday || !t.isAfter(now)) {
        t = t.add(Duration(days: 1));
      }
    } else if (!t.isAfter(now) && !todayOnly) {
      t = t.add(Duration(days: 1));
    }
    return tz.TZDateTime.from(t.toUtc(), tz.UTC);
  }

  /// إعادة جدولة كل التذكيرات حسب الإعدادات ونشاط النهارده.
  static Future<void> reschedule() async {
    await init();
    if (!_ready) return;
    try {
      await _n.cancel(id: _daily);
      await _n.cancel(id: _streak);
      await _n.cancel(id: _weekly);
      final m = Progress.reminderMinute;
      if (m < 0) return;
      final txt = _dailyTexts[math.Random().nextInt(_dailyTexts.length)];
      await _n.zonedSchedule(
        id: _daily,
        title: txt.$1,
        body: txt.$2,
        scheduledDate: _next(m ~/ 60, m % 60),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'hifz',
      );
      // السلسلة هتنقطع: لو ماعملتش حاجة النهارده وعندك سلسلة، نفكّرك الساعة ٩:٣٠ بالليل
      final streak = Progress.streak;
      final now = DateTime.now();
      final at = _next(21, 30, todayOnly: true);
      if (streak > 0 && !Progress.activeOn(now) && at.isAfter(tz.TZDateTime.now(tz.UTC))) {
        await _n.zonedSchedule(
          id: _streak,
          title: 'سلسلتك (${streak} يوم) هتنقطع!',
          body: 'آية واحدة تكفي عشان تحافظ عليها. افتح سَنَد دلوقتي.',
          scheduledDate: at,
          notificationDetails: _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'hifz',
        );
      }
      await _n.zonedSchedule(
        id: _weekly,
        title: 'تقرير أسبوعك جاهز',
        body: 'شوف حفظت كام آية الأسبوع ده، والآيات اللي محتاجة مراجعة.',
        scheduledDate: _next(10, 0, weekday: DateTime.friday),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'weekly',
      );
    } catch (_) {}
  }
}
