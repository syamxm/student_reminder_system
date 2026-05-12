import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../app/app_navigator.dart';
import '../../features/reminders/presentation/reminder_tap_screen.dart';
import 'notification_payload.dart';

class NotificationTapRouter {
  const NotificationTapRouter._();

  static String? _pendingReminderId;

  static void handleResponse(NotificationResponse? response) {
    final reminderId = NotificationPayload.parseReminderId(response?.payload);

    if (reminderId == null) {
      return;
    }

    _pendingReminderId = reminderId;
    openPendingIfPossible();
  }

  static void openPendingIfPossible() {
    final reminderId = _pendingReminderId;

    if (reminderId == null || reminderId.isEmpty) {
      return;
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      return;
    }

    _pendingReminderId = null;

    navigator.pushNamed(ReminderTapScreen.routeName, arguments: reminderId);
  }
}
