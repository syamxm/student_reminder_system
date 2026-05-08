import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  final User user;
  final AuthRepo repository;

  @override
  Widget build(BuildContext context) {
    final userProfileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: repository.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: userProfileStream,
          builder: (context, snapshot) {
            final profile = snapshot.data?.data();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _WelcomeCard(
                  displayName: profile?['displayName'] as String? ?? 'Student',
                  email: profile?['email'] as String? ?? user.email ?? '',
                  authProvider:
                      profile?['authProvider'] as String? ?? 'unknown',
                ),
                const SizedBox(height: 18),

                _DashboardInfoCard(
                  icon: Icons.task_alt_rounded,
                  title: 'Tasks',
                  value: 'Coming soon',
                  description: 'Assignments, homework, and study reminders.',
                ),
                const SizedBox(height: 12),

                _DashboardInfoCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Timetable',
                  value: 'Coming soon',
                  description: 'Weekly class schedule and study sessions.',
                ),
                const SizedBox(height: 12),

                _DashboardInfoCard(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Streak',
                  value: '${profile?['streakCount'] ?? 0} days',
                  description: 'Tracks consistent task completion.',
                ),
                const SizedBox(height: 12),

                _DashboardInfoCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Missed Deadlines',
                  value: '${profile?['missedDeadlinesCount'] ?? 0}',
                  description: 'Tracks overdue or missed tasks.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.displayName,
    required this.email,
    required this.authProvider,
  });

  final String displayName;
  final String email;
  final String authProvider;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $displayName',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(email.isEmpty ? 'No email found' : email),
            const SizedBox(height: 12),
            Chip(label: Text('Signed in with $authProvider')),
          ],
        ),
      ),
    );
  }
}

class _DashboardInfoCard extends StatelessWidget {
  const _DashboardInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
