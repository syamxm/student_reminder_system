import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';         
import 'package:student_reminder_system/core/theme_provider.dart'; 

import '../features/auth/presentation/auth_gate.dart';
import '../features/reminders/presentation/reminder_tap_screen.dart';
import 'app_navigator.dart';

class StudentReminderApp extends ConsumerWidget {
  const StudentReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =  ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Student Reminder System',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      home: AuthGate(),
      themeMode: themeMode,  

      onGenerateRoute: (settings) {
        if (settings.name == ReminderTapScreen.routeName) {
          final reminderId = settings.arguments as String?;

          return MaterialPageRoute(
            builder: (_) => ReminderTapScreen(reminderId: reminderId ?? ''),
            settings: settings,
          );
        }
        return null;
      },
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
    );
  }
}
