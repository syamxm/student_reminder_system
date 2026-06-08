import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'edit_reminder_screen.dart';
import 'reminder_card.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';
import 'package:student_reminder_system/features/streak/data/streak_repo.dart';

class ReminderList extends StatefulWidget {
  const ReminderList({
    super.key,
    this.limit,
    this.categoryFilter,
    this.groupBySubject = false,
  });

  final int? limit;
  final String? categoryFilter;
  final bool groupBySubject;

  @override
  State<ReminderList> createState() => _ReminderListState();
}

class _ReminderListState extends State<ReminderList> {
  final ReminderRepo _reminderRepo = ReminderRepo();
  final StreakRepo _streakRepo = StreakRepo();

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

        final all = snapshot.data ?? const <ReminderModel>[];

        final filter = widget.categoryFilter;
        final reminders =
            (filter == null
                  ? all.toList()
                  : all.where((r) => r.category == filter).toList())
              ..sort(_compare);

        if (reminders.isEmpty) {
          return const _EmptyReminderState();
        }

        if (widget.groupBySubject) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: _buildGroupedChildren(reminders),
          );
        }

        final visibleReminders = widget.limit == null
            ? reminders
            : reminders.take(widget.limit!).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: visibleReminders.length,
          itemBuilder: (context, index) {
            return _buildCard(visibleReminders[index]);
          },
        );
      },
    );
  }

  /// Incomplete first, then due date ascending, then priority descending.
  int _compare(ReminderModel a, ReminderModel b) {
    if (a.isCompleted != b.isCompleted) {
      return a.isCompleted ? 1 : -1;
    }

    final byDue = a.dueAt.compareTo(b.dueAt);
    if (byDue != 0) return byDue;

    return b.priority.index.compareTo(a.priority.index);
  }

  List<Widget> _buildGroupedChildren(List<ReminderModel> reminders) {
    const noSubject = 'No subject';
    final groups = <String, List<ReminderModel>>{};

    for (final reminder in reminders) {
      final name = (reminder.subjectName?.trim().isNotEmpty ?? false)
          ? reminder.subjectName!.trim()
          : noSubject;
      groups.putIfAbsent(name, () => []).add(reminder);
    }

    final keys = groups.keys.toList()
      ..sort((a, b) {
        if (a == noSubject) return 1;
        if (b == noSubject) return -1;
        return groups[a]!.first.dueAt.compareTo(groups[b]!.first.dueAt);
      });

    final children = <Widget>[];
    for (final key in keys) {
      children.add(_SubjectHeader(label: key));
      children.addAll(groups[key]!.map(_buildCard));
    }
    return children;
  }

  Widget _buildCard(ReminderModel reminder) {
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
        await _setCompletion(reminder, isCompleted);
      },
      onDeletePressed: () async {
        await _confirmDelete(reminder);
      },
    );
  }

  Future<void> _setCompletion(
    ReminderModel reminder,
    bool isCompleted,
  ) async {
    try {
      if (isCompleted && reminder.recurrence != ReminderRecurrence.none) {
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
          isCompleted: isCompleted,
        );
        if (isCompleted) {
          await NotificationService.instance.cancelAllReminderNotifications(
            reminder.id,
            reminder.reminderDaysBefore,
          );
        } else {
          await NotificationService.instance.scheduleReminderNotification(
            reminderId: reminder.id,
            title: reminder.title,
            description: reminder.description,
            dueAt: reminder.dueAt,
          );
          if (reminder.reminderDaysBefore.isNotEmpty) {
            await NotificationService.instance.scheduleEarlyReminders(
              reminderId: reminder.id,
              title: reminder.title,
              dueAt: reminder.dueAt,
              dayOffsets: reminder.reminderDaysBefore,
            );
          }
        }
      }

      if (isCompleted) {
        await _recordStreak(reminder.dueAt);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder: $error')),
        );
      }
    }
  }

  Future<void> _recordStreak(DateTime dueAt) async {
    try {
      await _streakRepo.recordCompletion(dueAt: dueAt);
    } catch (_) {
      // Streak update is best-effort; the reminder is already marked done.
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
      await NotificationService.instance.cancelAllReminderNotifications(
        reminder.id,
        reminder.reminderDaysBefore,
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

class _SubjectHeader extends StatelessWidget {
  const _SubjectHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          Icon(
            Icons.book_outlined,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
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
