import 'dart:convert';

class NotificationPayload {
  const NotificationPayload._();

  static String reminder({required String reminderId}) {
    return jsonEncode({'type': 'reminder', 'reminderId': reminderId});
  }

  static String? parseReminderId(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final type = decoded['type'];
      final reminderId = decoded['reminderId'];

      if (type != 'reminder') {
        return null;
      }

      if (reminderId is! String || reminderId.trim().isEmpty) {
        return null;
      }

      return reminderId.trim();
    } catch (_) {
      return null;
    }
  }
}
