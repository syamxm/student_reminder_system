import 'package:flutter/material.dart';

import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';
import 'package:student_reminder_system/features/timetable/presentation/timetable_edit_screen.dart';
import 'package:student_reminder_system/features/timetable/presentation/timetable_import_screen.dart';

String _formatTimeRange(String start, String end) =>
    '${_formatTime12(start)} - ${_formatTime12(end)}';

String _formatTime12(String raw) {
  final match = RegExp(
    r'^(\d{1,2}):?(\d{2})\s*(AM|PM)?$',
    caseSensitive: false,
  ).firstMatch(raw.trim());
  if (match == null) return raw;

  var h = int.tryParse(match.group(1)!);
  final m = match.group(2)!;
  if (h == null) return raw;

  String? period = match.group(3)?.toUpperCase();
  if (h >= 13) {
    h -= 12;
    period = 'PM';
  } else if (h == 0) {
    h = 12;
    period = 'AM';
  } else if (h == 12) {
    period ??= 'PM';
  } else {
    period ??= 'AM';
  }
  return '${h.toString().padLeft(2, '0')}:$m $period';
}

enum _View { today, week }

class TimetableTab extends StatefulWidget {
  const TimetableTab({super.key});

  @override
  State<TimetableTab> createState() => _TimetableTabState();
}

class _TimetableTabState extends State<TimetableTab> {
  final _repo = TimetableRepo();

  _View _view = _View.today;

  static const _dayOrder = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  String get _todayName => _dayOrder[DateTime.now().weekday - 1];

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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Timetable',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 8),
                    SegmentedButton<_View>(
                      segments: const [
                        ButtonSegment(
                          value: _View.today,
                          label: Text('Today'),
                        ),
                        ButtonSegment(value: _View.week, label: Text('Week')),
                      ],
                      selected: {_view},
                      onSelectionChanged: (selection) =>
                          setState(() => _view = selection.first),
                    ),
                  ],
                ),
              ),
            ),
            ...(_view == _View.today
                ? _todaySlivers(entries)
                : _weekSlivers(entries)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }

  List<Widget> _weekSlivers(List<TimetableModel> entries) {
    final grouped = _groupByDay(entries);
    return [
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
              (context, index) => _TimetableCard(entry: grouped[day]![index]),
              childCount: grouped[day]!.length,
            ),
          ),
        ],
    ];
  }

  List<Widget> _todaySlivers(List<TimetableModel> entries) {
    final today = entries.where((e) => e.day == _todayName).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (today.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              children: [
                Text(
                  'No classes today 🎉',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Switch to Week to see your full schedule.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return [
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TimetableCard(entry: today[index]),
          childCount: today.length,
        ),
      ),
    ];
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeRange(entry.startTime, entry.endTime),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (entry.room.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                              ),
                            ),
                          ],
                        ),
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
