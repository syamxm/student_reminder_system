import 'package:cloud_firestore/cloud_firestore.dart';

enum ReminderPriority { low, medium, high }

extension ReminderPriorityX on ReminderPriority {
  String get value {
    switch (this) {
      case ReminderPriority.low:
        return 'low';
      case ReminderPriority.medium:
        return 'medium';
      case ReminderPriority.high:
        return 'high';
    }
  }

  static ReminderPriority fromString(String value) {
    switch (value) {
      case 'high':
        return ReminderPriority.high;
      case 'medium':
        return ReminderPriority.medium;
      case 'low':
      default:
        return ReminderPriority.low;
    }
  }
}

enum ReminderRecurrence { none, daily, weekly, monthly }

extension ReminderRecurrenceX on ReminderRecurrence {
  String get value {
    switch (this) {
      case ReminderRecurrence.none:
        return 'none';
      case ReminderRecurrence.daily:
        return 'daily';
      case ReminderRecurrence.weekly:
        return 'weekly';
      case ReminderRecurrence.monthly:
        return 'monthly';
    }
  }

  static ReminderRecurrence fromString(String value) {
    switch (value) {
      case 'daily':
        return ReminderRecurrence.daily;
      case 'weekly':
        return ReminderRecurrence.weekly;
      case 'monthly':
        return ReminderRecurrence.monthly;
      case 'none':
      default:
        return ReminderRecurrence.none;
    }
  }

  DateTime? nextDueDate(DateTime from) {
    switch (this) {
      case ReminderRecurrence.none:
        return null;
      case ReminderRecurrence.daily:
        return from.add(const Duration(days: 1));
      case ReminderRecurrence.weekly:
        return from.add(const Duration(days: 7));
      case ReminderRecurrence.monthly:
        return DateTime(
          from.year,
          from.month + 1,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }
}

class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.priority,
    required this.isCompleted,
    this.recurrence = ReminderRecurrence.none,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final ReminderPriority priority;
  final bool isCompleted;
  final ReminderRecurrence recurrence;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReminderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Reminder document data is null.');
    }

    return ReminderModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      dueAt: _timestampToDate(data['dueAt']) ?? DateTime.now(),
      priority: ReminderPriorityX.fromString(
        data['priority'] as String? ?? 'low',
      ),
      isCompleted: data['isCompleted'] as bool? ?? false,
      recurrence: ReminderRecurrenceX.fromString(
        data['recurrence'] as String? ?? 'none',
      ),
      createdAt: _timestampToDate(data['createdAt']),
      updatedAt: _timestampToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'title': title,
      'description': description,
      'dueAt': Timestamp.fromDate(dueAt),
      'priority': priority.value,
      'isCompleted': isCompleted,
      'recurrence': recurrence.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'description': description,
      'dueAt': Timestamp.fromDate(dueAt),
      'priority': priority.value,
      'isCompleted': isCompleted,
      'recurrence': recurrence.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueAt,
    ReminderPriority? priority,
    bool? isCompleted,
    ReminderRecurrence? recurrence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueAt: dueAt ?? this.dueAt,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      recurrence: recurrence ?? this.recurrence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
