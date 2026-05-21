import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableModel {
  const TimetableModel({
    required this.id,
    required this.userId,
    required this.semesterCode,
    required this.subjectCode,
    required this.subjectName,
    required this.groupCode,
    required this.campus,
    required this.faculty,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.mode,
    required this.importedAt,
  });

  final String id;
  final String userId;
  final String semesterCode;
  final String subjectCode;
  final String subjectName;
  final String groupCode;
  final String campus;
  final String faculty;
  final String day;
  final String startTime;
  final String endTime;
  final String room;
  final String mode;
  final DateTime importedAt;

  factory TimetableModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Timetable document data is null.');
    }

    return TimetableModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      semesterCode: data['semesterCode'] as String? ?? '',
      subjectCode: data['subjectCode'] as String? ?? '',
      subjectName: data['subjectName'] as String? ?? '',
      groupCode: data['groupCode'] as String? ?? '',
      campus: data['campus'] as String? ?? '',
      faculty: data['faculty'] as String? ?? '',
      day: data['day'] as String? ?? '',
      startTime: data['startTime'] as String? ?? '',
      endTime: data['endTime'] as String? ?? '',
      room: data['room'] as String? ?? '',
      mode: data['mode'] as String? ?? '',
      importedAt: (data['importedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'semesterCode': semesterCode,
      'subjectCode': subjectCode,
      'subjectName': subjectName,
      'groupCode': groupCode,
      'campus': campus,
      'faculty': faculty,
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'mode': mode,
      'importedAt': Timestamp.fromDate(importedAt),
    };
  }

  TimetableModel copyWith({
    String? id,
    String? userId,
    String? semesterCode,
    String? subjectCode,
    String? subjectName,
    String? groupCode,
    String? campus,
    String? faculty,
    String? day,
    String? startTime,
    String? endTime,
    String? room,
    String? mode,
    DateTime? importedAt,
  }) {
    return TimetableModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      semesterCode: semesterCode ?? this.semesterCode,
      subjectCode: subjectCode ?? this.subjectCode,
      subjectName: subjectName ?? this.subjectName,
      groupCode: groupCode ?? this.groupCode,
      campus: campus ?? this.campus,
      faculty: faculty ?? this.faculty,
      day: day ?? this.day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      mode: mode ?? this.mode,
      importedAt: importedAt ?? this.importedAt,
    );
  }
}
