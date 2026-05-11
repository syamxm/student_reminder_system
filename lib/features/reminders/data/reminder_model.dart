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

class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    required this.priority,
    required this.isCompleted,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueAt;
  final ReminderPriority priority;
  final bool isCompleted;
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
