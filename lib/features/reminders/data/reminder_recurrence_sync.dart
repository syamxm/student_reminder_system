import 'dart:developer';

import 'package:student_reminder_system/core/notifications/notification_service.dart';

import 'reminder_model.dart';
import 'reminder_repo.dart';

/// Rolls recurring reminders forward to their next occurrence once the daily
/// reset boundary after their due time has passed.
///
/// Marking a recurring reminder done only completes it for the current cycle.
/// The actual advance happens here, at the next [resetHour]:[resetMinute]
/// boundary after `dueAt` — clearing completion and rescheduling notifications.
class ReminderRecurrenceSync {
  ReminderRecurrenceSync({ReminderRepo? reminderRepo})
    : _reminderRepo = reminderRepo ?? ReminderRepo();

  final ReminderRepo _reminderRepo;

  /// Time of day the reset runs. Default midnight. Override for testing,
  /// e.g. `ReminderRecurrenceSync.resetHour = 18` to roll over at 6pm.
  static int resetHour = 0;
  static int resetMinute = 0;

  Future<void> sync() async {
    try {
      final now = DateTime.now();
      final reminders = await _reminderRepo.watchReminders().first;

      for (final reminder in reminders) {
        if (reminder.recurrence == ReminderRecurrence.none) continue;

        final nextDue = _nextDueAfterReset(reminder, now);
        if (nextDue == null) continue;

        await _advance(reminder, nextDue);
      }
    } catch (error, stackTrace) {
      log('ReminderRecurrenceSync failed', error: error, stackTrace: stackTrace);
    }
  }

  /// Walks `dueAt` forward while its reset boundary has already passed.
  /// Returns the new due date, or null if no advance is needed.
  DateTime? _nextDueAfterReset(ReminderModel reminder, DateTime now) {
    var due = reminder.dueAt;

    while (!now.isBefore(_resetBoundaryAfter(due))) {
      final next = reminder.recurrence.nextDueDate(due);
      if (next == null) break;
      due = next;
    }

    return due.isAfter(reminder.dueAt) ? due : null;
  }

  /// First reset instant strictly after [from].
  DateTime _resetBoundaryAfter(DateTime from) {
    final boundary = DateTime(
      from.year,
      from.month,
      from.day,
      resetHour,
      resetMinute,
    );
    return boundary.isAfter(from)
        ? boundary
        : boundary.add(const Duration(days: 1));
  }

  Future<void> _advance(ReminderModel reminder, DateTime nextDue) async {
    await _reminderRepo.rescheduleRecurringTo(
      reminderId: reminder.id,
      dueAt: nextDue,
    );

    await NotificationService.instance.scheduleReminderNotification(
      reminderId: reminder.id,
      title: reminder.title,
      description: reminder.description,
      dueAt: nextDue,
    );

    if (reminder.reminderDaysBefore.isNotEmpty) {
      await NotificationService.instance.scheduleEarlyReminders(
        reminderId: reminder.id,
        title: reminder.title,
        dueAt: nextDue,
        dayOffsets: reminder.reminderDaysBefore,
      );
    }
  }
}
