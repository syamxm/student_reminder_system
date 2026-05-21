final Map<String, DateTime> semesterStartDates = {
  '20244': DateTime(2024, 10, 6),
  '20251': DateTime(2025, 7, 28),
  '20252': DateTime(2026, 3, 2),
};

const Map<String, String> semesterLabels = {
  '20244': 'Oct 2024 – Feb 2025',
  '20251': 'Jul – Dec 2025',
  '20252': 'Mar – Aug 2026',
};

int getCurrentWeek(String semesterCode) {
  final start = semesterStartDates[semesterCode];
  if (start == null) return 0;
  final diff = DateTime.now().difference(start).inDays;
  if (diff < 0) return 0;
  return (diff ~/ 7) + 1;
}

String getWeekLabel(int week) {
  if (week <= 0) return 'Pre-semester';
  if (week <= 7) return 'Week $week';
  if (week == 8) return 'Week 8 — Mid-semester break';
  if (week <= 14) return 'Week $week';
  if (week == 15) return 'Week 15 — Revision';
  if (week >= 16) return 'Week $week — Exam period';
  return 'Week $week';
}
