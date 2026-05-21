import 'package:flutter/material.dart';

import '../data/reminder_model.dart';
import '../data/reminder_repo.dart';
import 'package:student_reminder_system/core/notifications/notification_service.dart';

class EditReminderScreen extends StatefulWidget {
  const EditReminderScreen({super.key, required this.reminder});

  final ReminderModel reminder;

  @override
  State<EditReminderScreen> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reminderRepo = ReminderRepo();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late ReminderPriority _selectedPriority;
  late ReminderRecurrence _selectedRecurrence;
  late List<int> _selectedReminderDays;
  late bool _isCompleted;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.reminder.title);
    _descriptionController = TextEditingController(
      text: widget.reminder.description,
    );

    _selectedDate = widget.reminder.dueAt;
    _selectedTime = TimeOfDay.fromDateTime(widget.reminder.dueAt);
    _selectedPriority = widget.reminder.priority;
    _selectedRecurrence = widget.reminder.recurrence;
    _selectedReminderDays = List<int>.from(widget.reminder.reminderDaysBefore);
    _isCompleted = widget.reminder.isCompleted;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Edit Reminder')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Update Reminder',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Edit task details, deadline, priority, or completion status.',
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
                    onChanged: _isSaving
                        ? null
                        : (value) {
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
                    onChanged: _isSaving
                        ? null
                        : (value) {
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

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Completed'),
                    subtitle: const Text('Mark this reminder as done.'),
                    value: _isCompleted,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _isCompleted = value;
                            });
                          },
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
                      onPressed: _isSaving ? null : _saveChanges,
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

  Future<void> _saveChanges() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    setState(() {
      _isSaving = true;
    });

    final updatedReminder = widget.reminder.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueAt: _dueAt,
      priority: _selectedPriority,
      recurrence: _selectedRecurrence,
      reminderDaysBefore: _selectedReminderDays,
      isCompleted: _isCompleted,
    );

    try {
      await _reminderRepo.updateReminder(updatedReminder);

      if (_isCompleted) {
        await NotificationService.instance.cancelAllReminderNotifications(
          widget.reminder.id,
          widget.reminder.reminderDaysBefore,
        );
      } else {
        await NotificationService.instance.scheduleReminderNotification(
          reminderId: widget.reminder.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueAt: _dueAt,
        );

        if (_selectedReminderDays.isNotEmpty) {
          await NotificationService.instance.scheduleEarlyReminders(
            reminderId: widget.reminder.id,
            title: _titleController.text.trim(),
            dueAt: _dueAt,
            dayOffsets: _selectedReminderDays,
          );
        } else {
          await NotificationService.instance.cancelEarlyReminderNotifications(
            widget.reminder.id,
            widget.reminder.reminderDaysBefore,
          );
        }
      }

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update reminder: $error')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
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
