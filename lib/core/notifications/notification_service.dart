import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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
      onDidReceiveNotificationResponse: (response) {
        log('Notification tapped. payload=${response.payload}');
      },
    );

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
