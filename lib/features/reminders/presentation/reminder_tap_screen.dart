import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'edit_reminder_screen.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';
import 'package:student_reminder_system/features/streak/data/streak_repo.dart';

class ReminderTapScreen extends StatefulWidget {
  const ReminderTapScreen({super.key, required this.reminderId});

  static const routeName = '/reminder-tap';

  final String reminderId;

  @override
  State<ReminderTapScreen> createState() => _ReminderTapScreenState();
}

class _ReminderTapScreenState extends State<ReminderTapScreen> {
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _reminderFuture;
  final ReminderRepo _reminderRepo = ReminderRepo();
  final StreakRepo _streakRepo = StreakRepo();

  @override
  void initState() {
    super.initState();
    _reminderFuture = _loadReminder();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _loadReminder() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User is not logged in.');

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc(widget.reminderId)
        .get();
  }

  Future<void> _toggleCompletion(ReminderModel reminder) async {
    try {
      final markingComplete = !reminder.isCompleted;

      if (markingComplete && reminder.recurrence != ReminderRecurrence.none) {
        await _reminderRepo.advanceRecurringReminder(reminder);
        final nextDue = reminder.recurrence.nextDueDate(reminder.dueAt)!;
        await NotificationService.instance.scheduleReminderNotification(
          reminderId: reminder.id,
          title: reminder.title,
          description: reminder.description,
          dueAt: nextDue,
        );
        if (reminder.reminderDaysBefore.isNotEmpty) {
          await NotificationService.instance.scheduleEarlyReminders(
            reminderId: reminder.id,
            title: reminder.title,
            dueAt: nextDue,
            dayOffsets: reminder.reminderDaysBefore,
          );
        }
      } else {
        await _reminderRepo.setReminderCompletion(
          reminderId: reminder.id,
          isCompleted: markingComplete,
        );
        await NotificationService.instance.cancelAllReminderNotifications(
          reminder.id,
          reminder.reminderDaysBefore,
        );
      }

      if (markingComplete) {
        try {
          await _streakRepo.recordCompletion(dueAt: reminder.dueAt);
        } catch (_) {
          // Streak update is best-effort; the reminder is already marked done.
        }
      }

      if (mounted) Navigator.of(context).pop();
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
      builder: (context) => AlertDialog(
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
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _reminderRepo.deleteReminder(reminder.id);
      await NotificationService.instance.cancelAllReminderNotifications(
        reminder.id,
        reminder.reminderDaysBefore,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete reminder: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _reminderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _MessageView(
              title: 'Cannot open reminder',
              message: snapshot.error.toString(),
            );
          }

          final doc = snapshot.data;
          if (doc == null || !doc.exists) {
            return const _MessageView(
              title: 'Reminder not found',
              message: 'This reminder may have been deleted.',
            );
          }

          final reminder = ReminderModel.fromFirestore(doc);
          final theme = Theme.of(context);
          final cs = theme.colorScheme;

          return Column(
            children: [
              // Tappable detail body → edit
              Expanded(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditReminderScreen(reminder: reminder),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          reminder.title.isNotEmpty
                              ? reminder.title
                              : 'Untitled reminder',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: reminder.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: reminder.isCompleted
                                ? cs.onSurfaceVariant
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Due date row
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDueDate(reminder.dueAt),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Priority badge
                        _PriorityBadge(priority: reminder.priority),
                        const SizedBox(height: 20),

                        // Full description
                        if (reminder.description.trim().isNotEmpty)
                          Text(
                            reminder.description,
                            style: theme.textTheme.bodyLarge,
                          ),

                        const Spacer(),

                        // Tap hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to edit',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    // Toggle complete
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _toggleCompletion(reminder),
                        icon: Icon(
                          reminder.isCompleted
                              ? Icons.unpublished_outlined
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          reminder.isCompleted
                              ? 'Mark incomplete'
                              : 'Mark complete',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete
                    IconButton.filled(
                      onPressed: () => _confirmDelete(reminder),
                      icon: const Icon(Icons.delete_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.errorContainer,
                        foregroundColor: cs.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _formatDueDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final ReminderPriority priority;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (label, color) = switch (priority) {
      ReminderPriority.high => ('High Priority', cs.error),
      ReminderPriority.medium => ('Medium Priority', cs.tertiary),
      ReminderPriority.low => ('Low Priority', cs.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
