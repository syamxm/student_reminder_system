import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'timetable_model.dart';

class TimetableRepo {
  TimetableRepo({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  String get _uid {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('User is not signed in.');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _timetableRef =>
      _firestore.collection('users').doc(_uid).collection('timetable');

  Stream<List<TimetableModel>> watchTimetable() {
    return _timetableRef.snapshots().map(
      (snap) => snap.docs.map(TimetableModel.fromFirestore).toList(),
    );
  }

  Future<void> saveTimetable(List<TimetableModel> entries) async {
    await clearTimetable();

    final batch = _firestore.batch();
    for (final entry in entries) {
      final ref = _timetableRef.doc();
      batch.set(ref, entry.toMap());
    }
    await batch.commit();
  }

  Future<void> updateEntry(TimetableModel entry) async {
    if (entry.id.isEmpty) throw ArgumentError('Entry ID cannot be empty.');
    await _timetableRef.doc(entry.id).update(entry.toMap());
  }

  Future<void> deleteEntry(String entryId) async {
    if (entryId.isEmpty) throw ArgumentError('Entry ID cannot be empty.');
    await _timetableRef.doc(entryId).delete();
  }

  Future<void> clearTimetable() async {
    final snap = await _timetableRef.get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
