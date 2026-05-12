import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'edit_reminder_screen.dart';
import 'reminder_card.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';

class ReminderList extends StatefulWidget {
  const ReminderList({super.key, this.limit});

  final int? limit;

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

        final visibleReminders = widget.limit == null
            ? reminders
            : reminders.take(widget.limit!).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: visibleReminders.length,
          itemBuilder: (context, index) {
            final reminder = visibleReminders[index];

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
      await NotificationService.instance.cancelReminderNotification(reminderId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder: $error')),
        );
      }
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
      await NotificationService.instance.cancelReminderNotification(
        reminder.id,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete reminder: $error')),
        );
      }
    }
  }
}

class _EmptyReminderState extends StatelessWidget {
  const _EmptyReminderState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_alt_rounded,
              size: 54,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              'No reminders yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first assignment, study plan, or deadline.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
