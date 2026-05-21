import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'reminder_model.dart';

class ReminderRepo {
  ReminderRepo({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _uid {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('User is not signed in.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _remindersRef {
    return _firestore.collection('users').doc(_uid).collection('reminders');
  }

  Stream<List<ReminderModel>> watchReminders() {
    return _remindersRef.orderBy('dueAt').snapshots().map((snapshot) {
      final reminders = snapshot.docs.map(ReminderModel.fromFirestore).toList();

      reminders.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }

        return a.dueAt.compareTo(b.dueAt);
      });

      return reminders;
    });
  }

  Future<String> addReminder({
    required String title,
    required String description,
    required DateTime dueAt,
    required String priority,
    ReminderRecurrence recurrence = ReminderRecurrence.none,
    bool earlyRemindersEnabled = false,
  }) async {
    final uid = _firebaseAuth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not signed in.');
    }

    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('reminders')
        .doc();

    await docRef.set({
      'title': title,
      'description': description,
      'dueAt': Timestamp.fromDate(dueAt),
      'priority': priority,
      'isCompleted': false,
      'recurrence': recurrence.value,
      'earlyRemindersEnabled': earlyRemindersEnabled,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    if (reminder.id.trim().isEmpty) {
      throw ArgumentError('Reminder ID cannot be empty.');
    }

    if (reminder.title.trim().isEmpty) {
      throw ArgumentError('Reminder title cannot be empty.');
    }

    await _remindersRef.doc(reminder.id).update(reminder.toUpdateMap());
  }

  Future<void> setReminderCompletion({
    required String reminderId,
    required bool isCompleted,
  }) async {
    if (reminderId.trim().isEmpty) {
      throw ArgumentError('Reminder ID cannot be empty.');
    }

    await _remindersRef.doc(reminderId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReminder(String reminderId) async {
    if (reminderId.trim().isEmpty) {
      throw ArgumentError('Reminder ID cannot be empty.');
    }

    await _remindersRef.doc(reminderId).delete();
  }

  Future<void> advanceRecurringReminder(ReminderModel reminder) async {
    final nextDue = reminder.recurrence.nextDueDate(reminder.dueAt);

    if (nextDue == null) {
      throw StateError('Cannot advance non-recurring reminder.');
    }

    await _remindersRef.doc(reminder.id).update({
      'dueAt': Timestamp.fromDate(nextDue),
      'isCompleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
