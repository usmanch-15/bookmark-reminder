import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'prefs_service.dart';
import 'item_repository.dart';

const String snoozeActionId = 'snooze_10_action';
const String completeActionId = 'complete_action';

@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  if (response.actionId == snoozeActionId) {
    NotificationService()._snoozeById(response.id ?? 0);
  } else if (response.actionId == completeActionId) {
    // Best-effort: cancel the visible notification.
    // Marking the DB item 'completed' from a background isolate needs
    // Supabase re-init, so we keep this local-only and safe.
    NotificationService().cancelReminder(response.id ?? 0);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const _channelLow = 'reminder_channel_low';
  static const _channelMedium = 'reminder_channel_medium';
  static const _channelHigh = 'reminder_channel_high';

  Future<void> init() async {
    tzdata.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: notificationBackgroundHandler,
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelLow,
      'Reminders (Low priority)',
      description: 'Low priority reminders',
      importance: Importance.low,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelMedium,
      'Reminders (Medium priority)',
      description: 'Medium priority reminders',
      importance: Importance.defaultImportance,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _channelHigh,
      'Reminders (High priority)',
      description: 'High priority reminders',
      importance: Importance.max,
    ));
  }

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation
    AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  String _channelForPriority(int priority) {
    switch (priority) {
      case 2:
        return _channelHigh;
      case 0:
        return _channelLow;
      default:
        return _channelMedium;
    }
  }

  /// Checks quiet hours and, if active, pushes the reminder to the end
  /// of the quiet window instead of firing during it.
  Future<DateTime> _adjustForQuietHours(DateTime dateTime) async {
    final enabled = await PrefsService.isQuietHoursEnabled();
    if (!enabled) return dateTime;

    final startHour = await PrefsService.getQuietStartHour();
    final endHour = await PrefsService.getQuietEndHour();
    final hour = dateTime.hour;

    bool inQuietWindow;
    if (startHour <= endHour) {
      inQuietWindow = hour >= startHour && hour < endHour;
    } else {
      // Wraps past midnight, e.g. 22 -> 7
      inQuietWindow = hour >= startHour || hour < endHour;
    }

    if (!inQuietWindow) return dateTime;

    // Push to the end of the quiet window on the same or next day.
    var adjusted = DateTime(dateTime.year, dateTime.month, dateTime.day, endHour, 0);
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
    final soundOn = await PrefsService.isSoundEnabled();
    final vibrationOn = await PrefsService.isVibrationEnabled();
    final adjustedTime = await _adjustForQuietHours(dateTime);
    final channel = _channelForPriority(priority);

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
          actions: const [
            AndroidNotificationAction(completeActionId, 'Complete', showsUserInterface: false),
            AndroidNotificationAction(snoozeActionId, 'Snooze 10 min', showsUserInterface: false),
          ],
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> _snoozeById(int id) async {
    await _plugin.zonedSchedule(
      id,
      'Reminder (Snoozed)',
      'Tap to view details',
      tz.TZDateTime.now(tz.local).add(const Duration(minutes: 10)),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelMedium,
          'Reminders',
          channelDescription: 'Bookmark Reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
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
          _channelMedium,
          'Reminders',
          channelDescription: 'Bookmark Reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}