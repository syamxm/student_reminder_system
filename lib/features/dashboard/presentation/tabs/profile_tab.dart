import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_reminder_system/core/theme_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/dashboard_info_card.dart';
import 'package:student_reminder_system/features/dashboard/presentation/widgets/welcome_card.dart';
import 'package:student_reminder_system/core/notifications/class_notification_sync.dart';
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
            ),
            const SizedBox(height: 18),

            if (profile?.campus != null) ...[
              DashboardInfoCard(
                icon: Icons.location_city_rounded,
                title: 'Campus',
                value: profile!.campus!,
                description: '',
              ),
              const SizedBox(height: 12),
            ],

            if (profile?.faculty != null) ...[
              DashboardInfoCard(
                icon: Icons.school_rounded,
                title: 'Faculty',
                value: profile!.faculty!,
                description: '',
              ),
              const SizedBox(height: 12),
            ],

            if (profile?.activeSemester != null) ...[
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
              const SizedBox(height: 12),
            ],

            const SizedBox(height: 6),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                      ProfileScreen(user: user, repository: repository),
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

            Consumer(
              builder: (context, ref, _) {
                final mode = ref.watch(themeModeProvider);
                return Card(
                  margin: EdgeInsets.zero,
                  child: SwitchListTile(
                    secondary: Icon(
                      mode == ThemeMode.dark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                    ),
                    title: const Text('Dark mode'),
                    subtitle: const Text('Switch app appearance'),
                    value: mode == ThemeMode.dark,
                    onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: () async => repository.signOut(),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
