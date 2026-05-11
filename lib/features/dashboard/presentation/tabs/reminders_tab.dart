import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/reminders/presentation/reminder_list.dart';

class RemindersTab extends StatelessWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(padding: EdgeInsets.all(20), child: ReminderList());
  }
}
