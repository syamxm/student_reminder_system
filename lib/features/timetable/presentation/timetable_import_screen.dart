import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/api/timetable_api.dart';
import 'package:student_reminder_system/core/semester_engine.dart';
import 'package:student_reminder_system/features/profile/data/profile_repo.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_model.dart';
import 'package:student_reminder_system/features/timetable/data/timetable_repo.dart';

class TimetableImportScreen extends StatefulWidget {
  const TimetableImportScreen({super.key});

  @override
  State<TimetableImportScreen> createState() => _TimetableImportScreenState();
}

class _TimetableImportScreenState extends State<TimetableImportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matricController = TextEditingController();
  final _api = TimetableApi();
  final _repo = TimetableRepo();
  final _profileRepo = ProfileRepo();

  ProgramGroup? _programGroup;
  String? _selectedSemester;
  bool _isLoading = false;
  String? _errorMessage;
  int? _importedCount;

  @override
  void initState() {
    super.initState();
    _loadActiveSemester();
  }

  @override
  void dispose() {
    _matricController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveSemester() async {
    final profile = await _profileRepo.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _programGroup = profile.programGroup;
        _selectedSemester = profile.activeSemester;
      });
    }
  }

  Widget _buildSemesterDropdown() {
    final group = _programGroup;
    final semesters = group != null
        ? semestersForGroup(group)
        : <AcademicSemester>[];
    final codes = semesters.map((s) => s.code).toSet();
    final value =
        (_selectedSemester != null && codes.contains(_selectedSemester))
        ? _selectedSemester
        : null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Semester',
        border: const OutlineInputBorder(),
        helperText: group == null ? 'Set your program group in Profile' : null,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...semesters.map(
          (s) => DropdownMenuItem(value: s.code, child: Text(s.label)),
        ),
      ],
      onChanged: group == null
          ? null
          : (v) => setState(() => _selectedSemester = v),
    );
  }

  Future<void> _import() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _importedCount = null;
    });

    try {
      final matric = _matricController.text.trim().toUpperCase();
      final raw = await _api.scrape(matric);
      final entries = _mapToModels(raw, matric);

      await _repo.saveTimetable(entries);

      if (mounted) {
        setState(() => _importedCount = _countSubjects(raw));
      }
    } on TimetableNotFoundException {
      if (mounted) {
        setState(
          () => _errorMessage = 'No timetable found for this matric number.',
        );
      }
    } on TimetableApiException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Import failed: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Unexpected error: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const _dayTranslation = {
    'Ahad': 'Sunday',
    'Isnin': 'Monday',
    'Selasa': 'Tuesday',
    'Rabu': 'Wednesday',
    'Khamis': 'Thursday',
    'Jumaat': 'Friday',
    'Sabtu': 'Saturday',
  };

  List<TimetableModel> _mapToModels(Map<String, dynamic> raw, String matric) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final group = raw['group'] as String? ?? '';
    final subjects = raw['subjects'] as List? ?? [];
    final semester = _selectedSemester ?? '';
    final now = DateTime.now();

    final entries = <TimetableModel>[];

    for (final subject in subjects) {
      final s = subject as Map<String, dynamic>;
      final subjectCode = s['courseid'] as String? ?? '';
      final subjectName = s['course_desc'] as String? ?? '';
      final schedule = s['schedule'] as List? ?? [];

      for (final slot in schedule) {
        final sl = slot as Map<String, dynamic>;
        final rawDay = sl['day'] as String? ?? '';
        final day = _dayTranslation[rawDay] ?? rawDay;
        final masa = sl['masa'] as String? ?? '';
        final room = sl['bilik'] as String? ?? '';
        final (startTime, endTime) = _parseMasa(masa);

        entries.add(
          TimetableModel(
            id: '',
            userId: uid,
            semesterCode: semester,
            subjectCode: subjectCode,
            subjectName: subjectName,
            groupCode: group,
            campus: '',
            faculty: '',
            day: day,
            startTime: startTime,
            endTime: endTime,
            room: room,
            mode: 'Face to Face',
            importedAt: now,
          ),
        );
      }
    }

    return entries;
  }

  (String, String) _parseMasa(String masa) {
    final parts = masa.split('-');
    if (parts.length < 2) return (masa, '');
    return (_formatTime(parts[0].trim()), _formatTime(parts[1].trim()));
  }

  String _formatTime(String t) {
    t = t.replaceAll(':', '');
    if (t.length == 4) return '${t.substring(0, 2)}:${t.substring(2)}';
    return t;
  }

  int _countSubjects(Map<String, dynamic> raw) {
    final subjects = raw['subjects'] as List? ?? [];
    return subjects.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Timetable')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Import from UiTM',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your matric number to fetch your timetable.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _matricController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Matric Number',
                      hintText: 'e.g. 2022123456',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Matric number is required.';
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  _buildSemesterDropdown(),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _import,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _isLoading ? 'Importing...' : 'Import Timetable',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_importedCount != null) ...[
              const SizedBox(height: 24),
              _SuccessBanner(subjectCount: _importedCount!),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              _ErrorBanner(
                message: _errorMessage!,
                onManualEntry: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _ManualEntryScreen()),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.subjectCount});

  final int subjectCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Imported $subjectCount subject${subjectCount == 1 ? '' : 's'} successfully.',
              style: TextStyle(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onManualEntry});

  final String message;
  final VoidCallback onManualEntry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: cs.onErrorContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onManualEntry,
            child: const Text('Enter timetable manually'),
          ),
        ],
      ),
    );
  }
}

class _ManualEntryScreen extends StatefulWidget {
  const _ManualEntryScreen();

  @override
  State<_ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<_ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TimetableRepo();
  final _profileRepo = ProfileRepo();

  final _subjectCodeController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _roomController = TextEditingController();

  ProgramGroup? _programGroup;
  String? _selectedDay;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String? _selectedSemester;

  bool _isSaving = false;

  static const _days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();
    _loadProgramGroup();
  }

  Future<void> _loadProgramGroup() async {
    final profile = await _profileRepo.getProfile();
    if (profile != null && mounted) {
      setState(() {
        _programGroup = profile.programGroup;
        _selectedSemester = profile.activeSemester;
      });
    }
  }

  Widget _buildSemesterDropdown() {
    final group = _programGroup;
    final semesters = group != null
        ? semestersForGroup(group)
        : <AcademicSemester>[];
    final codes = semesters.map((s) => s.code).toSet();
    final value =
        (_selectedSemester != null && codes.contains(_selectedSemester))
        ? _selectedSemester
        : null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Semester',
        border: const OutlineInputBorder(),
        helperText: group == null ? 'Set your program group in Profile' : null,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...semesters.map(
          (s) => DropdownMenuItem(value: s.code, child: Text(s.label)),
        ),
      ],
      onChanged: group == null
          ? null
          : (v) => setState(() => _selectedSemester = v),
    );
  }

  @override
  void dispose() {
    _subjectCodeController.dispose();
    _subjectNameController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final entry = TimetableModel(
        id: '',
        userId: uid,
        semesterCode: _selectedSemester ?? '',
        subjectCode: _subjectCodeController.text.trim().toUpperCase(),
        subjectName: _subjectNameController.text.trim(),
        groupCode: '',
        campus: '',
        faculty: '',
        day: _selectedDay ?? '',
        startTime: _formatTimeOfDay(_startTime),
        endTime: _formatTimeOfDay(_endTime),
        room: _roomController.text.trim(),
        mode: 'Face to Face',
        importedAt: DateTime.now(),
      );

      await _repo.saveTimetable([entry]);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Subject saved.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Subject Manually')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Subject Code',
                      hintText: 'e.g. CSC548',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Required.' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _subjectNameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Required.' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Day',
                      border: OutlineInputBorder(),
                    ),
                    items: _days
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedDay = v),
                    validator: (v) => v == null ? 'Select a day.' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _startTime,
                            );
                            if (t != null) setState(() => _startTime = t);
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('Start: ${_formatTimeOfDay(_startTime)}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _endTime,
                            );
                            if (t != null) setState(() => _endTime = t);
                          },
                          icon: const Icon(Icons.schedule_rounded),
                          label: Text('End: ${_formatTimeOfDay(_endTime)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _roomController,
                    decoration: const InputDecoration(
                      labelText: 'Room',
                      hintText: 'e.g. BK 4-12',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildSemesterDropdown(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Save Subject'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
