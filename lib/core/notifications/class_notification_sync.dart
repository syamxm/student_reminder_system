import 'dart:developer';

import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/profile/data/profile_repo.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';

import 'notification_service.dart';

const _dayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const _windowDays = 14;
const _leadMinutes = 10;

class ClassNotificationSync {
  ClassNotificationSync({TimetableRepo? timetableRepo, ProfileRepo? profileRepo})
    : _timetableRepo = timetableRepo ?? TimetableRepo(),
      _profileRepo = profileRepo ?? ProfileRepo();

  final TimetableRepo _timetableRepo;
  final ProfileRepo _profileRepo;

  Future<void> sync() async {
    try {
      await NotificationService.instance.cancelAllClassNotifications();

      final profile = await _profileRepo.getProfile();
      if (profile != null && !profile.classRemindersEnabled) return;

      final entries = await _timetableRepo.watchTimetable().first;
      if (entries.isEmpty) return;

      AcademicSemester? semester;
      if (profile?.programGroup != null && profile?.activeSemester != null) {
        semester = findSemester(profile!.programGroup!, profile.activeSemester!);
      }

      final today = DateTime.now();
      for (var offset = 0; offset < _windowDays; offset++) {
        final date = DateTime(today.year, today.month, today.day + offset);

        if (semester != null && !isLectureDate(semester, date)) continue;

        final dayName = _dayNames[date.weekday - 1];
        for (final entry in entries) {
          if (entry.day != dayName) continue;
          await _scheduleEntry(entry, date);
        }
      }
    } catch (error, stackTrace) {
      log('ClassNotificationSync failed', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _scheduleEntry(TimetableModel entry, DateTime date) async {
    final parts = entry.startTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    final start = DateTime(date.year, date.month, date.day, hour, minute);
    final notifyAt = start.subtract(const Duration(minutes: _leadMinutes));

    final dateKey =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    final id = 'class_${entry.id}_$dateKey'.hashCode & 0x7fffffff;

    await NotificationService.instance.scheduleClassNotification(
      id: id,
      subjectCode: entry.subjectCode,
      subjectName: entry.subjectName,
      room: entry.room,
      notifyAt: notifyAt,
      entryId: entry.id,
    );
  }
}
