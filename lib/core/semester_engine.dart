enum ProgramGroup { a, b }

String programGroupCode(ProgramGroup group) => group == ProgramGroup.a ? 'A' : 'B';

ProgramGroup? programGroupFromCode(String? code) {
  switch (code) {
    case 'A':
      return ProgramGroup.a;
    case 'B':
      return ProgramGroup.b;
    default:
      return null;
  }
}

String programGroupLabel(ProgramGroup group) => group == ProgramGroup.a
    ? 'Group A — Foundation / Professional'
    : 'Group B — Diploma / Bachelor / Postgrad';

class SemesterPhase {
  const SemesterPhase(this.label, this.start, this.end, {this.isLecture = false});

  final String label;
  final DateTime start; // inclusive
  final DateTime end; // inclusive
  final bool isLecture;
}

class AcademicSemester {
  const AcademicSemester(this.code, this.group, this.label, this.phases);

  final String code;
  final ProgramGroup group;
  final String label;
  final List<SemesterPhase> phases;
}

// Dates transcribed from the official UiTM academic calendar (Session 2025/2026).
// https://hea.uitm.edu.my/index.php/calendars/academic-calendar
// Group A = Foundation/Professional. Group B = Pre-Diploma/Diploma/Bachelor/Master/PhD.
// State-variant (*) dates, Part-1 interim weeks and EET rows are intentionally omitted.
// TODO: add Session 2026/2027 once published.
final List<AcademicSemester> academicCalendar = [
  AcademicSemester('20254', ProgramGroup.a, 'Jul – Dec 2025', [
    SemesterPhase('Lecture', _d(2025, 7, 14), _d(2025, 8, 31), isLecture: true),
    SemesterPhase('Mid-Semester Test', _d(2025, 9, 1), _d(2025, 9, 7)),
    SemesterPhase('Mid-Semester Break', _d(2025, 9, 8), _d(2025, 9, 14)),
    SemesterPhase('Lecture', _d(2025, 9, 15), _d(2025, 11, 2), isLecture: true),
    SemesterPhase('Revision Week', _d(2025, 11, 3), _d(2025, 11, 9)),
    SemesterPhase('Final Examination', _d(2025, 11, 10), _d(2025, 11, 23)),
    SemesterPhase('Semester Break', _d(2025, 11, 24), _d(2025, 12, 21)),
  ]),
  AcademicSemester('20262', ProgramGroup.a, 'Jan – Jun 2026', [
    SemesterPhase('Online Lecture', _d(2025, 12, 22), _d(2025, 12, 28), isLecture: true),
    SemesterPhase('Lecture', _d(2025, 12, 29), _d(2026, 2, 8), isLecture: true),
    SemesterPhase('Mid-Semester Test', _d(2026, 2, 9), _d(2026, 2, 15)),
    SemesterPhase('Mid-Semester Break', _d(2026, 2, 16), _d(2026, 2, 22)),
    SemesterPhase('Lecture', _d(2026, 2, 23), _d(2026, 3, 19), isLecture: true),
    SemesterPhase('Special Break', _d(2026, 3, 20), _d(2026, 3, 29)),
    SemesterPhase('Lecture', _d(2026, 3, 30), _d(2026, 4, 19), isLecture: true),
    SemesterPhase('Revision Week', _d(2026, 4, 20), _d(2026, 4, 26)),
    SemesterPhase('Final Examination', _d(2026, 4, 27), _d(2026, 5, 10)),
    SemesterPhase('Semester Break', _d(2026, 5, 11), _d(2026, 6, 14)),
  ]),
  AcademicSemester('20254', ProgramGroup.b, 'Oct 2025 – Feb 2026', [
    SemesterPhase('Lecture', _d(2025, 10, 6), _d(2025, 11, 23), isLecture: true),
    SemesterPhase('Mid-Semester Break', _d(2025, 11, 24), _d(2025, 11, 30)),
    SemesterPhase('Lecture', _d(2025, 12, 1), _d(2025, 12, 21), isLecture: true),
    SemesterPhase('Special Break', _d(2025, 12, 22), _d(2025, 12, 28)),
    SemesterPhase('Lecture', _d(2025, 12, 29), _d(2026, 1, 25), isLecture: true),
    SemesterPhase('Revision Week', _d(2026, 1, 26), _d(2026, 2, 1)),
    SemesterPhase('Final Examination', _d(2026, 2, 2), _d(2026, 2, 22)),
    SemesterPhase('Semester Break', _d(2026, 2, 23), _d(2026, 3, 22)),
  ]),
  AcademicSemester('20262', ProgramGroup.b, 'Mar – Aug 2026', [
    SemesterPhase('Lecture', _d(2026, 3, 30), _d(2026, 5, 24), isLecture: true),
    SemesterPhase('Mid-Semester Break', _d(2026, 5, 25), _d(2026, 6, 2)),
    SemesterPhase('Lecture', _d(2026, 6, 3), _d(2026, 7, 12), isLecture: true),
    SemesterPhase('Revision Week', _d(2026, 7, 13), _d(2026, 7, 19)),
    SemesterPhase('Final Examination', _d(2026, 7, 20), _d(2026, 8, 9)),
    SemesterPhase('Semester Break', _d(2026, 8, 10), _d(2026, 9, 27)),
  ]),
  AcademicSemester('20263', ProgramGroup.b, 'Aug – Sep 2026 (Short Sem)', [
    SemesterPhase('Lecture', _d(2026, 8, 3), _d(2026, 9, 20), isLecture: true),
    SemesterPhase('Examination', _d(2026, 9, 21), _d(2026, 9, 25)),
    SemesterPhase('Semester Break', _d(2026, 9, 26), _d(2026, 9, 27)),
  ]),
];

DateTime _d(int y, int m, int day) => DateTime(y, m, day);

DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);

int _weeksIn(SemesterPhase p) => (p.end.difference(p.start).inDays ~/ 7) + 1;

List<AcademicSemester> semestersForGroup(ProgramGroup group) =>
    academicCalendar.where((s) => s.group == group).toList();

AcademicSemester? findSemester(ProgramGroup group, String code) {
  for (final s in academicCalendar) {
    if (s.group == group && s.code == code) return s;
  }
  return null;
}

bool isLectureDate(AcademicSemester sem, DateTime date) {
  final day = _dateOnly(date);
  for (final p in sem.phases) {
    if (p.isLecture && !day.isBefore(p.start) && !day.isAfter(p.end)) {
      return true;
    }
  }
  return false;
}

String currentStatusLabel(AcademicSemester sem, [DateTime? now]) {
  final today = _dateOnly(now ?? DateTime.now());

  if (today.isBefore(sem.phases.first.start)) return 'Pre-semester';
  if (today.isAfter(sem.phases.last.end)) return 'Semester ended';

  var lectureWeeksBefore = 0;
  for (final p in sem.phases) {
    if (today.isBefore(p.start)) return 'Semester break';

    if (!today.isAfter(p.end)) {
      if (p.isLecture) {
        final week = lectureWeeksBefore + (today.difference(p.start).inDays ~/ 7) + 1;
        return 'Week $week';
      }
      return p.label;
    }

    if (p.isLecture) lectureWeeksBefore += _weeksIn(p);
  }

  return 'Semester ended';
}
