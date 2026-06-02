import 'package:flutter/material.dart';

import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';
import 'package:student_reminder_system/features/timetable/presentation/timetable_edit_screen.dart';
import 'package:student_reminder_system/features/timetable/presentation/timetable_import_screen.dart';

class TimetableTab extends StatefulWidget {
  const TimetableTab({super.key});

  @override
  State<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<TimetableTab> {
  final _repo = TimetableRepo();

  static const _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, List<TimetableModel>> _groupByDay(List<TimetableModel> entries) {
    final map = <String, List<TimetableModel>>{};
    for (final e in entries) {
      (map[e.day] ??= []).add(e);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TimetableModel>>(
      stream: _repo.watchTimetable(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return _EmptyState();
        }

        final grouped = _groupByDay(entries);

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timetable',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const TimetableImportScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Re-import'),
                    ),
                  ],
                ),
              ),
            ),
            for (final day in _dayOrder)
              if (grouped.containsKey(day)) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _TimetableCard(entry: grouped[day]![index]),
                    childCount: grouped[day]!.length,
                  ),
                ),
              ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            Text(
              'No timetable imported',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Import your UiTM timetable to see your schedule here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TimetableImportScreen(),
                ),
              ),
              icon: const Icon(Icons.download_rounded),
              label: const Text('Import Timetable'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimetableCard extends StatelessWidget {
  const _TimetableCard({required this.entry});

  final TimetableModel entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.subjectCode,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: cs.primary),
                  ),
                  Text(
                    entry.subjectName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.startTime} – ${entry.endTime}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (entry.room.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            entry.room,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined, color: cs.onSurfaceVariant),
              tooltip: 'Edit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TimetableEditScreen(entry: entry),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
