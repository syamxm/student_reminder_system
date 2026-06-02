import 'dart:convert';

class NotificationPayload {
  const NotificationPayload._();

  static String reminder({required String reminderId}) {
    return jsonEncode({'type': 'reminder', 'reminderId': reminderId});
  }

  static String classReminder({required String entryId}) {
    return jsonEncode({'type': 'class', 'entryId': entryId});
  }

  static String? parseClassEntryId(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);

      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      if (decoded['type'] != 'class') {
        return null;
      }

      final entryId = decoded['entryId'];

      if (entryId is! String || entryId.trim().isEmpty) {
        return null;
      }

      return entryId.trim();
    } catch (_) {
      return null;
    }
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
