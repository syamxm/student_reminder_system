import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'reminder_card.dart';
import 'edit_reminder_screen.dart';

class ReminderList extends StatefulWidget {
  const ReminderList({super.key});

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  final ReminderRepo _reminderRepo = ReminderRepo();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReminderModel>>(
      stream: _reminderRepo.watchReminders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load reminders.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final reminders = snapshot.data ?? const [];

        if (reminders.isEmpty) {
          return const _EmptyReminderState();
        }

        return ListView.builder(
          itemCount: reminders.length,
          itemBuilder: (context, index) {
            final reminder = reminders[index];

            return ReminderCard(
              reminder: reminder,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditReminderScreen(reminder: reminder),
                  ),
                );
              },
              onCompletionChanged: (isCompleted) async {
                await _setCompletion(
                  reminderId: reminder.id,
                  isCompleted: isCompleted,
                );
              },
              onDeletePressed: () async {
                await _confirmDelete(reminder);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _setCompletion({
    required String reminderId,
    required bool isCompleted,
  }) async {
    try {
      await _reminderRepo.setReminderCompletion(
        reminderId: reminderId,
        isCompleted: isCompleted,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reminder: $error')),
      );
    }
  }

  Future<void> _confirmDelete(ReminderModel reminder) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete reminder?'),
          content: Text('This will delete "${reminder.title}".'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await _reminderRepo.deleteReminder(reminder.id);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete reminder: $error')),
      );
    }
  }
}

class _EmptyReminderState extends StatelessWidget {
  const _EmptyReminderState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No reminders yet.\nAdd one soon.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
