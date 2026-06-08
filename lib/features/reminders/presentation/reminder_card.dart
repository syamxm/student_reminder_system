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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Priority accent bar
              Container(width: 4, color: priorityColor),

              // Card body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Checkbox
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: reminder.isCompleted,
                          visualDensity: VisualDensity.compact,
                          onChanged: (value) {
                            if (value == null) return;
                            onCompletionChanged(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title + priority badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    reminder.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: reminder.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: reminder.isCompleted
                                          ? theme.colorScheme.onSurfaceVariant
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _PriorityBadge(
                                  label: _priorityLabel(reminder.priority),
                                  color: priorityColor,
                                ),
                              ],
                            ),

                            // Category + subject
                            if (_hasMeta(reminder)) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  if (_showCategory(reminder))
                                    _MetaChip(
                                      label: reminderCategoryLabel(
                                        reminder.category,
                                      ),
                                      color: theme.colorScheme.secondary,
                                    ),
                                  if (_showCategory(reminder) &&
                                      _hasSubject(reminder))
                                    const SizedBox(width: 6),
                                  if (_hasSubject(reminder))
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.book_outlined,
                                            size: 12,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              reminder.subjectName!.trim(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],

                            // Description
                            if (reminder.description.trim().isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                reminder.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Bottom row: datetime + status
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDateTime(reminder.dueAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                _StatusChip(status: status),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 3-dot menu
                      PopupMenuButton<_CardAction>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onSelected: (action) {
                          switch (action) {
                            case _CardAction.edit:
                              onTap();
                            case _CardAction.delete:
                              onDeletePressed();
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _CardAction.edit,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                const Text('Edit'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: _CardAction.delete,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: theme.colorScheme.error,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static bool _hasSubject(ReminderModel r) =>
      r.subjectName?.trim().isNotEmpty ?? false;

  static bool _showCategory(ReminderModel r) => r.category != 'general';

  static bool _hasMeta(ReminderModel r) => _showCategory(r) || _hasSubject(r);

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
    final cs = Theme.of(context).colorScheme;
    switch (priority) {
      case ReminderPriority.high:
        return cs.error;
      case ReminderPriority.medium:
        return cs.tertiary;
      case ReminderPriority.low:
        return cs.primary;
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

  static String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();

    final period = dt.hour >= 12 ? 'PM' : 'AM';
    var h = dt.hour % 12;
    if (h == 0) h = 12;
    final hh = h.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');

    return '$d/$mo/$y $hh:$mi $period';
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

enum _CardAction { edit, delete }

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final _DueStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
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
