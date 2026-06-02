import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/dashboard_info_card.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/welcome_card.dart';
import 'package:student_reminder_system/core/notifications/class_notification_sync.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';
import 'package:student_reminder_system/features/profile/data/profile_repo.dart';
import 'package:student_reminder_system/features/profile/data/user_profile_model.dart';
import 'package:student_reminder_system/features/profile/presentation/profile_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.user, required this.repository});

  final User user;
  final AuthRepo repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfileModel?>(
      stream: ProfileRepo().watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            WelcomeCard(
              displayName: profile?.displayName ?? user.displayName ?? 'Student',
              email: profile?.email ?? user.email ?? '',
              authProvider: 'google',
            ),
            const SizedBox(height: 18),

            if (profile?.campus != null)
              DashboardInfoCard(
                icon: Icons.location_city_rounded,
                title: 'Campus',
                value: profile!.campus!,
                description: '',
              ),
            if (profile?.campus != null) const SizedBox(height: 12),

            if (profile?.faculty != null)
              DashboardInfoCard(
                icon: Icons.school_rounded,
                title: 'Faculty',
                value: profile!.faculty!,
                description: '',
              ),
            if (profile?.faculty != null) const SizedBox(height: 12),

            if (profile?.activeSemester != null)
              DashboardInfoCard(
                icon: Icons.calendar_today_rounded,
                title: 'Active Semester',
                value: profile!.programGroup != null
                    ? (findSemester(
                            profile.programGroup!,
                            profile.activeSemester!,
                          )?.label ??
                          profile.activeSemester!)
                    : profile.activeSemester!,
                description: '',
              ),
            if (profile?.activeSemester != null) const SizedBox(height: 12),

            DashboardInfoCard(
              icon: Icons.badge_outlined,
              title: 'User ID',
              value: 'View',
              description: user.uid,
            ),
            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: user),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 12),

            Card(
              margin: EdgeInsets.zero,
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Class reminders'),
                subtitle: const Text('Notify 10 minutes before each class'),
                value: profile?.classRemindersEnabled ?? true,
                onChanged: profile == null
                    ? null
                    : (value) async {
                        await ProfileRepo().saveProfile(
                          profile.copyWith(classRemindersEnabled: value),
                        );
                        await ClassNotificationSync().sync();
                      },
              ),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () async => repository.signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () async {
                await NotificationService.instance.showDebugNotification();
              },
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Send debug notification'),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                await NotificationService.instance.scheduleDebugNotification();
              },
              icon: const Icon(Icons.schedule_outlined),
              label: const Text('Schedule 10-second notification'),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
