import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'notification_payload.dart';
import 'notification_tap_router.dart';

int _notificationIdFromReminderId(String reminderId) {
  return reminderId.hashCode & 0x7fffffff;
}

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Do not navigate here.
  // Background callback may run outside normal UI isolate.
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  static const String _debugChannelId = 'reminder_debug_channel';
  static const String _debugChannelName = 'Reminder Debug';
  static const String _debugChannelDescription =
      'Debug notifications for reminder testing.';

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: NotificationTapRouter.handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final launchDetails = await _notifications
        .getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      NotificationTapRouter.handleResponse(launchDetails?.notificationResponse);
    }

    await requestPermission();

    _isInitialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();

      final timezoneId = _normalizeTimezoneId(timezone.identifier);

      tz.setLocalLocation(tz.getLocation(timezoneId));

      log('Local timezone configured: $timezoneId');
    } catch (error, stackTrace) {
      log(
        'Failed to configure local timezone. Falling back to tz.UTC.',
        error: error,
        stackTrace: stackTrace,
      );

      tz.setLocalLocation(tz.UTC);
    }
  }

  String _normalizeTimezoneId(String timezoneId) {
    final trimmed = timezoneId.trim();

    if (trimmed == 'UTC') return 'Etc/UTC';
    if (trimmed == 'GMT') return 'Etc/GMT';

    return trimmed;
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final granted = await androidPlugin?.requestNotificationsPermission();

    return granted ?? true;
  }

  static const String _reminderChannelId = 'reminder_due_channel';
  static const String _reminderChannelName = 'Reminder Due';
  static const String _reminderChannelDescription =
      'Notifications for scheduled student reminders.';

  NotificationDetails _reminderNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _reminderChannelId,
        _reminderChannelName,
        channelDescription: _reminderChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    await init();

    final notificationId = _notificationIdFromReminderId(reminderId);
    await _notifications.cancel(id: notificationId);

    log('Cancelled reminder notification: id=$notificationId');
  }

  Future<void> logPendingNotifications() async {
    await init();

    final pending = await _notifications.pendingNotificationRequests();

    log('Pending notifications count: ${pending.length}');

    for (final item in pending) {
      log(
        'Pending notification: id=${item.id}, title=${item.title}, body=${item.body}',
      );
    }
  }

  Future<void> scheduleReminderNotification({
    required String reminderId,
    required String title,
    String? description,
    required DateTime dueAt,
  }) async {
    await init();
    await requestPermission();

    if (dueAt.isBefore(DateTime.now())) {
      await cancelReminderNotification(reminderId);
      log('Skipped scheduling past reminder: $reminderId');
      return;
    }

    final scheduledDate = tz.TZDateTime.from(dueAt, tz.local);
    final notificationId = _notificationIdFromReminderId(reminderId);

    await _notifications.zonedSchedule(
      id: _notificationIdFromReminderId(reminderId),
      title: 'Reminder: $title',
      scheduledDate: scheduledDate,
      notificationDetails: _reminderNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: NotificationPayload.reminder(reminderId: reminderId),
    );

    log(
      'Scheduled reminder notification: id=$notificationId dueAt=$scheduledDate',
    );
  }

  NotificationDetails _debugNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _debugChannelId,
        _debugChannelName,
        channelDescription: _debugChannelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  Future<void> showDebugNotification() async {
    await init();

    await _notifications.show(
      id: 1001,
      title: 'Student Reminder System',
      body: 'Debug notification works.',
      notificationDetails: _debugNotificationDetails(),
      payload: 'debug_notification',
    );
  }

  Future<void> scheduleDebugNotification() async {
    await init();

    await Future.delayed(const Duration(seconds: 10));
    await _notifications.show(
      id: 1002,
      title: 'Scheduled Debug Reminder',
      body: 'This notification was scheduled 10 seconds ago.',
      notificationDetails: _debugNotificationDetails(),
      payload: 'scheduled_debug_notification',
    );
  }

  Future<void> cancelDebugNotifications() async {
    await _notifications.cancel(id: 1001);
    await _notifications.cancel(id: 1002);
  }
}
