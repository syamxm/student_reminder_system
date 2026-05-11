import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/dashboard_info_card.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/welcome_card.dart';
import 'package:student_reminder_system/features/reminders/presentation/reminder_list.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final userProfileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userProfileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WelcomeCard(
              displayName: profile?['displayName'] as String? ?? 'Student',
              email: profile?['email'] as String? ?? user.email ?? '',
              authProvider: profile?['authProvider'] as String? ?? 'unknown',
            ),
            const SizedBox(height: 18),
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
              value: '${profile?['streakCount'] ?? 0} days',
              description: 'Tracks consistent task completion.',
            ),
            const SizedBox(height: 12),
            DashboardInfoCard(
              icon: Icons.warning_amber_rounded,
              title: 'Missed Deadlines',
              value: '${profile?['missedDeadlinesCount'] ?? 0}',
              description: 'Tracks overdue or missed tasks.',
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Reminders',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const SizedBox(height: 300, child: ReminderList(limit: 3)),
          ],
        );
      },
    );
  }
}
