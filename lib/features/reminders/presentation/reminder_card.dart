import 'package:flutter/material.dart';

import '../data/reminder_model.dart';

class ReminderCard extends StatelessWidget {
  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onTap,
    required this.onCompletionChanged,
    required this.onDeletePressed,
  });

  final ReminderModel reminder;
  final VoidCallback onTap;
  final ValueChanged<bool> onCompletionChanged;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _dueStatus(reminder.dueAt, reminder.isCompleted);
    final priorityColor = _priorityColor(context, reminder.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: reminder.isCompleted,
                onChanged: (value) {
                  if (value == null) return;
                  onCompletionChanged(value);
                },
              ),
              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        decoration: reminder.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),

                    if (reminder.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        reminder.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.schedule_rounded,
                          label: _formatDateTime(reminder.dueAt),
                        ),
                        _ColoredChip(
                          icon: Icons.flag_rounded,
                          label: _priorityLabel(reminder.priority),
                          color: priorityColor,
                        ),
                        _ColoredChip(
                          icon: status.icon,
                          label: status.label,
                          color: status.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  IconButton(
                    tooltip: 'Edit reminder',
                    onPressed: onTap,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete reminder',
                    onPressed: onDeletePressed,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _priorityLabel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.high:
        return 'High';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.low:
        return 'Low';
    }
  }

  static Color _priorityColor(BuildContext context, ReminderPriority priority) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (priority) {
      case ReminderPriority.high:
        return colorScheme.error;
      case ReminderPriority.medium:
        return colorScheme.tertiary;
      case ReminderPriority.low:
        return colorScheme.primary;
    }
  }

  static _DueStatus _dueStatus(DateTime dueAt, bool isCompleted) {
    if (isCompleted) {
      return _DueStatus(
        label: 'Done',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);

    if (dueAt.isBefore(now)) {
      return _DueStatus(
        label: 'Overdue',
        icon: Icons.warning_amber_rounded,
        color: Colors.red,
      );
    }

    if (dueDay == today) {
      return _DueStatus(
        label: 'Today',
        icon: Icons.today_rounded,
        color: Colors.orange,
      );
    }

    return _DueStatus(
      label: 'Upcoming',
      icon: Icons.upcoming_rounded,
      color: Colors.blue,
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$year-$month-$day $hour:$minute';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ColoredChip extends StatelessWidget {
  const _ColoredChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.35)),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w700),
    );
  }
}

class _DueStatus {
  const _DueStatus({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
