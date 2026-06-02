import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';
import 'reminder_form_fields.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reminderRepo = ReminderRepo();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subjectController = TextEditingController();

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  ReminderPriority _selectedPriority = ReminderPriority.medium;
  ReminderRecurrence _selectedRecurrence = ReminderRecurrence.none;
  List<int> _selectedReminderDays = const [];

  String _selectedCategory = 'general';
  bool _categoryManual = false;

  List<TimetableModel> _subjects = const [];
  String? _selectedSubjectCode;
  bool _subjectManual = false;
  bool _subjectsLoading = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjects() async {
    try {
      final entries = await TimetableRepo().watchTimetable().first;
      if (!mounted) return;
      setState(() {
        _subjects = uniqueSubjects(entries);
        _subjectsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _subjectsLoading = false);
    }
  }

  DateTime get _dueAt {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reminder')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Create Reminder',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Add assignments, study plans, or deadlines.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Example: Submit assignment',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final title = value?.trim() ?? '';

                      if (title.isEmpty) {
                        return 'Title is required.';
                      }

                      if (title.length < 3) {
                        return 'Title must be at least 3 characters.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional details',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  CategoryField(
                    selectedCategory: _selectedCategory,
                    manual: _categoryManual,
                    controller: _categoryController,
                    enabled: !_isSaving,
                    onCategoryChanged: (value) =>
                        setState(() => _selectedCategory = value),
                    onManualChanged: (value) =>
                        setState(() => _categoryManual = value),
                  ),

                  const SizedBox(height: 14),

                  SubjectField(
                    subjects: _subjects,
                    loading: _subjectsLoading,
                    selectedSubjectCode: _selectedSubjectCode,
                    manual: _subjectManual,
                    controller: _subjectController,
                    enabled: !_isSaving,
                    onSubjectChanged: (code) =>
                        setState(() => _selectedSubjectCode = code),
                    onManualChanged: (value) =>
                        setState(() => _subjectManual = value),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<ReminderPriority>(
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: ReminderPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(_priorityLabel(priority)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedPriority = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<ReminderRecurrence>(
                    initialValue: _selectedRecurrence,
                    decoration: const InputDecoration(
                      labelText: 'Recurrence',
                      border: OutlineInputBorder(),
                    ),
                    items: ReminderRecurrence.values.map((recurrence) {
                      return DropdownMenuItem(
                        value: recurrence,
                        child: Text(_recurrenceLabel(recurrence)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedRecurrence = value;
                      });
                    },
                  ),

                  const SizedBox(height: 14),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Early reminders'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [1, 3, 7, 14].map((days) {
                          return FilterChip(
                            label: Text(
                              days == 1 ? '1 day before' : '$days days before',
                            ),
                            selected: _selectedReminderDays.contains(days),
                            onSelected: _isSaving
                                ? null
                                : (selected) {
                                    setState(() {
                                      _selectedReminderDays = selected
                                          ? [..._selectedReminderDays, days]
                                          : _selectedReminderDays
                                                .where((d) => d != days)
                                                .toList();
                                    });
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickDate,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(_formatDate(_selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _pickTime,
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveReminder,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Reminder'),
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  Future<void> _saveReminder() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    try {
      final category = _resolveCategory();
      final subject = _resolveSubject();

      final reminderId = await _reminderRepo.addReminder(
        ReminderModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueAt: _dueAt,
          priority: _selectedPriority,
          isCompleted: false,
          recurrence: _selectedRecurrence,
          reminderDaysBefore: _selectedReminderDays,
          category: category,
          subjectCode: subject.code,
          subjectName: subject.name,
          semesterCode: subject.semesterCode,
        ),
      );

      await NotificationService.instance.scheduleReminderNotification(
        reminderId: reminderId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueAt: _dueAt,
      );

      if (_selectedReminderDays.isNotEmpty) {
        await NotificationService.instance.scheduleEarlyReminders(
          reminderId: reminderId,
          title: _titleController.text.trim(),
          dueAt: _dueAt,
          dayOffsets: _selectedReminderDays,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save reminder: $error')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _resolveCategory() {
    if (_categoryManual) {
      final text = _categoryController.text.trim();
      return text.isEmpty ? 'general' : text;
    }
    return _selectedCategory;
  }

  ({String? code, String? name, String? semesterCode}) _resolveSubject() {
    if (_subjectManual) {
      final text = _subjectController.text.trim();
      return (code: null, name: text.isEmpty ? null : text, semesterCode: null);
    }
    final code = _selectedSubjectCode;
    if (code == null) {
      return (code: null, name: null, semesterCode: null);
    }
    final entry = _subjects.firstWhere((s) => s.subjectCode == code);
    return (
      code: entry.subjectCode,
      name: entry.subjectName,
      semesterCode: entry.semesterCode,
    );
  }

  String _priorityLabel(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.low:
        return 'Low';
      case ReminderPriority.medium:
        return 'Medium';
      case ReminderPriority.high:
        return 'High';
    }
  }

  String _recurrenceLabel(ReminderRecurrence recurrence) {
    switch (recurrence) {
      case ReminderRecurrence.none:
        return 'Does not repeat';
      case ReminderRecurrence.daily:
        return 'Daily';
      case ReminderRecurrence.weekly:
        return 'Weekly';
      case ReminderRecurrence.monthly:
        return 'Monthly';
    }
  }

  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString();
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }
}
