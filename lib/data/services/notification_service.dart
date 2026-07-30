import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'prefs_service.dart';

const String snoozeActionId = 'snooze_10_action';
const String completeActionId = 'complete_action';

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  if (response.actionId == snoozeActionId) {
    NotificationService().snoozeById(response.id ?? 0);
  } else if (response.actionId == completeActionId) {
    NotificationService().cancelReminder(response.id ?? 0);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String channelLow = 'reminder_channel_low';
  static const String channelMedium = 'reminder_channel_medium';
  static const String channelHigh = 'reminder_channel_high';

  Future<void> init() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: notificationBackgroundHandler,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelLow,
          'Reminders (Low priority)',
          description: 'Low priority reminders',
          importance: Importance.low,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelMedium,
          'Reminders (Medium priority)',
          description: 'Medium priority reminders',
          importance: Importance.defaultImportance,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelHigh,
          'Reminders (High priority)',
          description: 'High priority reminders',
          importance: Importance.max,
        ),
      );
    }
  }

  Future<void> requestPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  String _channelForPriority(int priority) {
    if (priority == 2) return channelHigh;
    if (priority == 0) return channelLow;
    return channelMedium;
  }

  Future<DateTime> _adjustForQuietHours(DateTime dateTime) async {
    final bool enabled = await PrefsService.isQuietHoursEnabled();
    if (!enabled) return dateTime;

    final int startHour = await PrefsService.getQuietStartHour();
    final int endHour = await PrefsService.getQuietEndHour();
    final int hour = dateTime.hour;

    bool inQuietWindow;
    if (startHour <= endHour) {
      inQuietWindow = hour >= startHour && hour < endHour;
    } else {
      inQuietWindow = hour >= startHour || hour < endHour;
    }

    if (!inQuietWindow) return dateTime;

    DateTime adjusted = DateTime(dateTime.year, dateTime.month, dateTime.day, endHour, 0);
    if (adjusted.isBefore(dateTime)) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    int priority = 1,
  }) async {
    final bool soundOn = await PrefsService.isSoundEnabled();
    final bool vibrationOn = await PrefsService.isVibrationEnabled();
    final DateTime adjustedTime = await _adjustForQuietHours(dateTime);
    final String channel = _channelForPriority(priority);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(adjustedTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          'Reminders',
          channelDescription: 'Bookmark Reminder notifications',
          importance: priority == 2 ? Importance.max : Importance.high,
          priority: priority == 2 ? Priority.max : Priority.high,
          playSound: soundOn,
          enableVibration: vibrationOn,
          actions: const <AndroidNotificationAction>[
            AndroidNotificationAction(completeActionId, 'Complete', showsUserInterface: false),
            AndroidNotificationAction(snoozeActionId, 'Snooze 10 min', showsUserInterface: false),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> snoozeById(int id) async {
    await _plugin.zonedSchedule(
      id,
      'Reminder (Snoozed)',
      'Tap to view details',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelMedium,
          'Reminders',
          channelDescription: 'Bookmark Reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> snoozeReminder({
    required int id,
    required String title,
    required String body,
    Duration duration = const Duration(minutes: 10),
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.now(tz.local).add(duration),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelMedium,
          'Reminders',
          channelDescription: 'Bookmark Reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}