import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';

class TimetableEditScreen extends StatefulWidget {
  const TimetableEditScreen({super.key, required this.entry});

  final TimetableModel entry;

  @override
  State<TimetableEditScreen> createState() => _TimetableEditScreenState();
}

class _TimetableEditScreenState extends State<TimetableEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TimetableRepo();

  late final _subjectCodeController = TextEditingController(
    text: widget.entry.subjectCode,
  );
  late final _subjectNameController = TextEditingController(
    text: widget.entry.subjectName,
  );
  late final _roomController = TextEditingController(text: widget.entry.room);

  late String? _selectedDay = widget.entry.day.isEmpty
      ? null
      : widget.entry.day;
  late TimeOfDay _startTime = _parseTime(widget.entry.startTime);
  late TimeOfDay _endTime = _parseTime(widget.entry.endTime);
  late String? _selectedSemester = widget.entry.semesterCode.isEmpty
      ? null
      : widget.entry.semesterCode;

  bool _isSaving = false;

  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 8, minute: 0);
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final updated = widget.entry.copyWith(
        subjectCode: _subjectCodeController.text.trim().toUpperCase(),
        subjectName: _subjectNameController.text.trim(),
        day: _selectedDay ?? '',
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        room: _roomController.text.trim(),
        semesterCode: _selectedSemester ?? '',
      );

      await _repo.updateEntry(updated);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text(
          'Remove "${widget.entry.subjectName}" from your timetable?',
        ),
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

    if (confirmed != true || !mounted) return;

    try {
      await _repo.deleteEntry(widget.entry.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subject'),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Subject Code',
                      hintText: 'e.g. CSC548',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectNameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Required.' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: _days
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDay = v),
                    validator: (v) => v == null ? 'Select a day.' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (t != null) setState(() => _startTime = t);
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('Start: ${_formatTimeOfDay(_startTime)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (t != null) setState(() => _endTime = t);
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('End: ${_formatTimeOfDay(_endTime)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room / Building',
                      hintText: 'e.g. CS1, CS2, BK 4-12',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Semester',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ...semesterStartDates.keys.map(
                        (code) => DropdownMenuItem(
                          value: code,
                          child: Text(semesterLabels[code] ?? code),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedSemester = v),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
