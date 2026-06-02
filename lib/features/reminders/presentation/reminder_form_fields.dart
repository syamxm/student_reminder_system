import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';

/// Category picker: dropdown of presets with a "Type manually" fallback.
class CategoryField extends StatelessWidget {
  const CategoryField({
    super.key,
    required this.selectedCategory,
    required this.manual,
    required this.controller,
    required this.enabled,
    required this.onCategoryChanged,
    required this.onManualChanged,
  });

  final String selectedCategory;
  final bool manual;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onManualChanged;

  @override
  Widget build(BuildContext context) {
    if (manual) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Category',
              hintText: 'e.g. Lab report',
              border: OutlineInputBorder(),
            ),
          ),
          TextButton(
            onPressed: enabled ? () => onManualChanged(false) : null,
            child: const Text('Choose from list'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedCategory,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Category',
            border: OutlineInputBorder(),
          ),
          items: reminderCategories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(reminderCategoryLabel(c)),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value == null) return;
                  onCategoryChanged(value);
                }
              : null,
        ),
        TextButton(
          onPressed: enabled ? () => onManualChanged(true) : null,
          child: const Text('Type manually'),
        ),
      ],
    );
  }
}

/// Subject picker: dropdown of timetable subjects with None + manual fallback.
class SubjectField extends StatelessWidget {
  const SubjectField({
    super.key,
    required this.subjects,
    required this.loading,
    required this.selectedSubjectCode,
    required this.manual,
    required this.controller,
    required this.enabled,
    required this.onSubjectChanged,
    required this.onManualChanged,
  });

  final List<TimetableModel> subjects;
  final bool loading;
  final String? selectedSubjectCode;
  final bool manual;
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<bool> onManualChanged;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const InputDecorator(
        decoration: InputDecoration(
          labelText: 'Subject',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading...'),
          ],
        ),
      );
    }

    if (manual || subjects.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: controller,
            enabled: enabled,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Subject',
              hintText: 'e.g. Software Engineering',
              border: OutlineInputBorder(),
            ),
          ),
          if (subjects.isNotEmpty)
            TextButton(
              onPressed: enabled ? () => onManualChanged(false) : null,
              child: const Text('Choose from list'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: selectedSubjectCode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Subject',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('None')),
            ...subjects.map(
              (s) => DropdownMenuItem(
                value: s.subjectCode,
                child: Text('${s.subjectCode} - ${s.subjectName}'),
              ),
            ),
          ],
          onChanged: enabled ? onSubjectChanged : null,
        ),
        TextButton(
          onPressed: enabled ? () => onManualChanged(true) : null,
          child: const Text('Type manually'),
        ),
      ],
    );
  }
}

/// Deduplicate timetable entries to one per subject code.
List<TimetableModel> uniqueSubjects(List<TimetableModel> entries) {
  final seen = <String>{};
  final result = <TimetableModel>[];
  for (final entry in entries) {
    if (entry.subjectCode.isEmpty) continue;
    if (seen.add(entry.subjectCode)) result.add(entry);
  }
  result.sort((a, b) => a.subjectCode.compareTo(b.subjectCode));
  return result;
}
