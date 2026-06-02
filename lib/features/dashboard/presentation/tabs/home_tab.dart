import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/dashboard_info_card.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/welcome_card.dart';
import 'package:student_reminder_system/features/profile/data/profile_repo.dart';
import 'package:student_reminder_system/features/profile/data/user_profile_model.dart';
import 'package:student_reminder_system/features/reminders/data/reminder_model.dart';
import 'package:student_reminder_system/features/reminders/data/reminder_repo.dart';
import 'package:student_reminder_system/features/reminders/presentation/reminder_list.dart';
import 'package:student_reminder_system/features/streak/data/streak_repo.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.user});

  final User user;

  int _streakDays(Map<String, dynamic>? userDoc) {
    final count = (userDoc?['streakCount'] as int?) ?? 0;
    final last = userDoc?['lastStreakDate'] as Timestamp?;
    return displayStreak(count, last?.toDate(), DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDocStream,
      builder: (context, userSnap) {
        final userDoc = userSnap.data?.data();

        return StreamBuilder<UserProfileModel?>(
          stream: ProfileRepo().watchProfile(),
          builder: (context, profileSnap) {
            final profile = profileSnap.data;

            final group = profile?.programGroup;
            final code = profile?.activeSemester;
            final semester = (group != null && code != null)
                ? findSemester(group, code)
                : null;
            final weekLabel =
                semester != null ? currentStatusLabel(semester) : null;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                WelcomeCard(
                  displayName:
                      userDoc?['displayName'] as String? ?? 'Student',
                  email: userDoc?['email'] as String? ?? user.email ?? '',
                  authProvider:
                      userDoc?['authProvider'] as String? ?? 'unknown',
                ),
                const SizedBox(height: 18),

                if (weekLabel != null) ...[
                  _WeekCard(semester: semester!.label, weekLabel: weekLabel),
                  const SizedBox(height: 12),
                ],

                const DashboardInfoCard(
                  icon: Icons.task_alt_rounded,
                  title: 'Tasks',
                  value: 'Active',
                  description: 'Assignments, homework, and study reminders.',
                ),
                const SizedBox(height: 12),
                const DashboardInfoCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Timetable',
                  value: 'Soon',
                  description: 'Weekly class schedule and study sessions.',
                ),
                const SizedBox(height: 12),
                DashboardInfoCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak',
                  value: '${_streakDays(userDoc)} days',
                  description: 'Tracks consistent task completion.',
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<ReminderModel>>(
                  stream: ReminderRepo().watchReminders(),
                  builder: (context, remindersSnap) {
                    final now = DateTime.now();
                    final missed = (remindersSnap.data ?? const <ReminderModel>[])
                        .where((r) => !r.isCompleted && r.dueAt.isBefore(now))
                        .length;

                    return DashboardInfoCard(
                      icon: Icons.warning_amber_rounded,
                      title: 'Missed Deadlines',
                      value: '$missed',
                      description: 'Tracks overdue or missed tasks.',
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Recent Reminders',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 300, child: ReminderList(limit: 3)),
              ],
            );
          },
        );
      },
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.semester, required this.weekLabel});

  final String semester;
  final String weekLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: cs.onPrimaryContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weekLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  semester,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
