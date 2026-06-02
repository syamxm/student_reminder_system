import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:student_reminder_system/core/semester_engine.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.campus,
    this.faculty,
    this.programGroup,
    this.activeSemester,
    this.lastTimetableSync,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? campus;
  final String? faculty;
  final ProgramGroup? programGroup;
  final String? activeSemester;
  final DateTime? lastTimetableSync;

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('UserProfile document data is null.');
    }

    return UserProfileModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      campus: data['campus'] as String?,
      faculty: data['faculty'] as String?,
      programGroup: programGroupFromCode(data['programGroup'] as String?),
      activeSemester: data['activeSemester'] as String?,
      lastTimetableSync:
          (data['lastTimetableSync'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'campus': campus,
      'faculty': faculty,
      'programGroup': programGroup != null ? programGroupCode(programGroup!) : null,
      'activeSemester': activeSemester,
      'lastTimetableSync': lastTimetableSync != null
          ? Timestamp.fromDate(lastTimetableSync!)
          : null,
    };
  }

  UserProfileModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? campus,
    String? faculty,
    ProgramGroup? programGroup,
    String? activeSemester,
    DateTime? lastTimetableSync,
  }) {
    return UserProfileModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      campus: campus ?? this.campus,
      faculty: faculty ?? this.faculty,
      programGroup: programGroup ?? this.programGroup,
      activeSemester: activeSemester ?? this.activeSemester,
      lastTimetableSync: lastTimetableSync ?? this.lastTimetableSync,
    );
  }
}
