import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/reminders/presentation/reminder_list.dart';

class RemindersTab extends StatefulWidget {
  const RemindersTab({super.key});

  @override
  State<RemindersTab> createState() => _RemindersTabState();
}

class _RemindersTabState extends State<RemindersTab> {
  static const _filters = [
    ('all', 'All'),
    ('test', 'Test'),
    ('assignment', 'Assignment'),
    ('project', 'Project'),
    ('general', 'General'),
    ('by_subject', 'By Subject'),
  ];

  String _selected = 'all';

  @override
  Widget build(BuildContext context) {
    final groupBySubject = _selected == 'by_subject';
    final categoryFilter = (_selected == 'all' || groupBySubject)
        ? null
        : _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _filters.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (key, label) = _filters[index];
              return FilterChip(
                label: Text(label),
                selected: _selected == key,
                onSelected: (_) => setState(() => _selected = key),
              );
            },
          ),
        ),
        Expanded(
          child: ReminderList(
            categoryFilter: categoryFilter,
            groupBySubject: groupBySubject,
          ),
        ),
      ],
    );
  }
}
