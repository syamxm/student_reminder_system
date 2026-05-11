import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/dashboard_info_card.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/welcome_card.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.user, required this.repository});

  final User user;
  final AuthRepo repository;

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
            DashboardInfoCard(
              icon: Icons.badge_outlined,
              title: 'User ID',
              value: 'View',
              description: user.uid,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await repository.signOut();
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
