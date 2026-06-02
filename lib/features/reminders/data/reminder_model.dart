import 'package:cloud_firestore/cloud_firestore.dart';

const reminderCategories = ['test', 'assignment', 'project', 'general'];

String reminderCategoryLabel(String category) {
  switch (category) {
    case 'test':
      return 'Test';
    case 'assignment':
      return 'Assignment';
    case 'project':
      return 'Project';
    case 'general':
      return 'General';
    default:
      if (category.isEmpty) return 'General';
      return category[0].toUpperCase() + category.substring(1);
  }
}

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
    this.reminderDaysBefore = const [],
    this.category = 'general',
    this.subjectCode,
    this.subjectName,
    this.weekNumber,
    this.semesterCode,
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
  final List<int> reminderDaysBefore;
  final String category;
  final String? subjectCode;
  final String? subjectName;
  final int? weekNumber;
  final String? semesterCode;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ReminderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Reminder document data is null.');
    }

    final List<int> reminderDaysBefore;
    final rawDays = data['reminderDaysBefore'];
    if (rawDays is List && rawDays.isNotEmpty) {
      reminderDaysBefore = rawDays.whereType<int>().toList();
    } else {
      final legacyEnabled = data['earlyRemindersEnabled'] as bool? ?? false;
      reminderDaysBefore = legacyEnabled ? [1] : [];
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
      reminderDaysBefore: reminderDaysBefore,
      category: data['category'] as String? ?? 'general',
      subjectCode: data['subjectCode'] as String?,
      subjectName: data['subjectName'] as String?,
      weekNumber: data['weekNumber'] as int?,
      semesterCode: data['semesterCode'] as String?,
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
      'reminderDaysBefore': reminderDaysBefore,
      'category': category,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'weekNumber': weekNumber,
      'semesterCode': semesterCode,
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
      'reminderDaysBefore': reminderDaysBefore,
      'category': category,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'weekNumber': weekNumber,
      'semesterCode': semesterCode,
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
    List<int>? reminderDaysBefore,
    String? category,
    String? subjectCode,
    String? subjectName,
    int? weekNumber,
    String? semesterCode,
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
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      category: category ?? this.category,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      weekNumber: weekNumber ?? this.weekNumber,
      semesterCode: semesterCode ?? this.semesterCode,
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
