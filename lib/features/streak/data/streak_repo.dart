import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Streak shown on the home card. Alive only if the last counted day was
/// today or yesterday; a skipped day means it has lapsed to 0.
int displayStreak(int streakCount, DateTime? lastStreakDate, DateTime now) {
  if (lastStreakDate == null) return 0;
  final diff = dateOnly(now).difference(dateOnly(lastStreakDate)).inDays;
  return diff <= 1 ? streakCount : 0;
}

class StreakRepo {
  StreakRepo({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
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

  DocumentReference<Map<String, dynamic>> get _userRef {
    return _firestore.collection('users').doc(_uid);
  }

  /// Update the daily streak when a task is marked complete. On-time
  /// completions extend the streak once per day; a late completion resets it.
  Future<void> recordCompletion({required DateTime dueAt}) async {
    final now = DateTime.now();
    final onTime = !now.isAfter(dueAt);
    final userRef = _userRef;

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      final data = snapshot.data() ?? <String, dynamic>{};

      if (!onTime) {
        tx.set(userRef, {
          'streakCount': 0,
          'lastStreakDate': null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      final today = dateOnly(now);
      final lastTimestamp = data['lastStreakDate'] as Timestamp?;
      final lastDate = lastTimestamp != null
          ? dateOnly(lastTimestamp.toDate())
          : null;
      final current = (data['streakCount'] as int?) ?? 0;

      if (lastDate == today) {
        return; // Already counted today.
      }

      final next = (lastDate != null && today.difference(lastDate).inDays == 1)
          ? current + 1
          : 1;

      tx.set(userRef, {
        'streakCount': next,
        'lastStreakDate': Timestamp.fromDate(today),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
