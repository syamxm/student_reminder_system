import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:student_reminder_system/core/api/timetable_api.dart';
import 'package:student_reminder_system/core/semester_engine.dart';
import '../data/profile_repo.dart';
import '../data/user_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProfileRepo();
  final _api = TimetableApi();

  final _campusController = TextEditingController();
  final _facultyController = TextEditingController();

  ProgramGroup? _selectedGroup;
  String? _selectedSemester;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _campuses = [];
  List<Map<String, dynamic>> _faculties = [];
  String? _selectedCampusCode;
  String? _selectedFacultyName;
  bool _campusManual = false;
  bool _facultyManual = false;
  bool _campusesLoading = false;
  bool _facultiesLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _campusController.dispose();
    _facultyController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _repo.getProfile();

    String? savedCampus;
    String? savedFaculty;

    if (profile != null) {
      savedCampus = profile.campus;
      savedFaculty = profile.faculty;
      _campusController.text = profile.campus ?? '';
      _facultyController.text = profile.faculty ?? '';
      _selectedGroup = profile.programGroup;
      _selectedSemester = profile.activeSemester;
    }

    await _loadCampuses(savedCampus: savedCampus, savedFaculty: savedFaculty);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadCampuses({
    String? savedCampus,
    String? savedFaculty,
  }) async {
    if (mounted) setState(() => _campusesLoading = true);
    try {
      final campuses = await _api.fetchCampuses();
      if (!mounted) return;
      setState(() {
        _campuses = campuses;
        _campusesLoading = false;
      });

      if (savedCampus != null && savedCampus.isNotEmpty) {
        final match = _findInList(_campuses, 'name', savedCampus);
        if (match != null) {
          final code = match['code'] as String;
          setState(() => _selectedCampusCode = code);
          if (code == (_campuses.first['code'] as String?)) {
            await _loadFaculties(code, savedFaculty: savedFaculty);
          } else if (mounted) {
            setState(() => _facultyManual = true);
          }
        } else {
          if (mounted) setState(() => _campusManual = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _campusesLoading = false;
          _campusManual = true;
        });
      }
    }
  }

  Future<void> _loadFaculties(
    String campusCode, {
    String? savedFaculty,
  }) async {
    if (mounted) setState(() { _facultiesLoading = true; _faculties = []; });
    try {
      final faculties = await _api.fetchFaculties(campusCode);
      if (!mounted) return;
      setState(() {
        _faculties = faculties;
        _facultiesLoading = false;
      });

      if (savedFaculty != null && savedFaculty.isNotEmpty) {
        final match = _findInList(_faculties, 'name', savedFaculty);
        if (match != null) {
          setState(() => _selectedFacultyName = match['name'] as String?);
        } else {
          if (mounted) setState(() => _facultyManual = true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _facultiesLoading = false;
          _facultyManual = true;
        });
      }
    }
  }

  bool get _isFirstCampusSelected =>
      _campuses.isNotEmpty &&
      _selectedCampusCode == (_campuses.first['code'] as String?);

  Map<String, dynamic>? _findInList(
    List<Map<String, dynamic>> list,
    String key,
    String value,
  ) {
    for (final item in list) {
      if ((item[key] as String?) == value) return item;
    }
    return null;
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    try {
      String? campus;
      if (_campusManual || _campuses.isEmpty) {
        final t = _campusController.text.trim();
        campus = t.isEmpty ? null : t;
      } else if (_selectedCampusCode != null) {
        campus = _findInList(_campuses, 'code', _selectedCampusCode!)?['name']
            as String?;
      }

      String? faculty;
      if (_facultyManual || _faculties.isEmpty) {
        final t = _facultyController.text.trim();
        faculty = t.isEmpty ? null : t;
      } else {
        faculty = _selectedFacultyName;
      }

      final profile = UserProfileModel(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        displayName: widget.user.displayName ?? '',
        campus: campus,
        faculty: faculty,
        programGroup: _selectedGroup,
        activeSemester: _selectedSemester,
      );

      await _repo.saveProfile(profile);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Your Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Update your campus, faculty, and active semester.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: widget.user.displayName ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: widget.user.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Campus
                  _buildCampusField(),

                  const SizedBox(height: 14),

                  // Faculty
                  _buildFacultyField(),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<ProgramGroup>(
                    initialValue: _selectedGroup,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Program Group',
                      border: OutlineInputBorder(),
                    ),
                    items: ProgramGroup.values
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(programGroupLabel(g)),
                          ),
                        )
                        .toList(),
                    onChanged: _isSaving
                        ? null
                        : (g) => setState(() {
                            _selectedGroup = g;
                            if (g == null ||
                                _selectedSemester == null ||
                                findSemester(g, _selectedSemester!) == null) {
                              _selectedSemester = null;
                            }
                          }),
                  ),

                  const SizedBox(height: 14),

                  _buildSemesterField(),

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
                      label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
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

  Widget _buildSemesterField() {
    final group = _selectedGroup;
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
        labelText: 'Active Semester',
        border: const OutlineInputBorder(),
        helperText: group == null ? 'Select a program group first' : null,
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('None')),
        ...semesters.map(
          (s) => DropdownMenuItem(value: s.code, child: Text(s.label)),
        ),
      ],
      onChanged: (group == null || _isSaving)
          ? null
          : (v) => setState(() => _selectedSemester = v),
    );
  }

  Widget _buildCampusField() {
    if (_campusesLoading) {
      return const _LoadingField(label: 'Campus');
    }

    if (_campusManual || _campuses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _campusController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Campus',
              hintText: 'e.g. Shah Alam',
              border: OutlineInputBorder(),
            ),
          ),
          if (_campuses.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _campusManual = false),
              child: const Text('Choose from list'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedCampusCode,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Campus',
            border: OutlineInputBorder(),
          ),
          items: _campuses
              .map(
                (c) => DropdownMenuItem(
                  value: c['code'] as String,
                  child: Text(c['name'] as String? ?? ''),
                ),
              )
              .toList(),
          onChanged: _isSaving
              ? null
              : (code) async {
                  if (code == null) return;
                  setState(() {
                    _selectedCampusCode = code;
                    _faculties = [];
                    _selectedFacultyName = null;
                    _facultyManual = false;
                  });
                  if (code == (_campuses.first['code'] as String?)) {
                    await _loadFaculties(code);
                  }
                },
        ),
        TextButton(
          onPressed: () {
            if (_selectedCampusCode != null) {
              final name =
                  _findInList(_campuses, 'code', _selectedCampusCode!)?[
                    'name'
                  ] as String? ??
                  '';
              _campusController.text = name;
            }
            setState(() => _campusManual = true);
          },
          child: const Text('Type manually'),
        ),
      ],
    );
  }

  Widget _buildFacultyField() {
    if (_facultiesLoading) {
      return const _LoadingField(label: 'Faculty');
    }

    final showDropdown = _isFirstCampusSelected &&
        !_facultyManual &&
        _faculties.isNotEmpty;

    if (showDropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedFacultyName,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Faculty',
              border: OutlineInputBorder(),
            ),
            items: _faculties
                .map(
                  (f) => DropdownMenuItem(
                    value: f['name'] as String,
                    child: Text(f['name'] as String? ?? ''),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (name) => setState(() => _selectedFacultyName = name),
          ),
          TextButton(
            onPressed: () {
              if (_selectedFacultyName != null) {
                _facultyController.text = _selectedFacultyName!;
              }
              setState(() => _facultyManual = true);
            },
            child: const Text('Type manually'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextFormField(
          controller: _facultyController,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Faculty',
            hintText: 'e.g. Faculty of Computer and Mathematical Sciences',
            border: OutlineInputBorder(),
          ),
        ),
        if (_isFirstCampusSelected && _faculties.isNotEmpty)
          TextButton(
            onPressed: () => setState(() => _facultyManual = false),
            child: const Text('Choose from list'),
          ),
      ],
    );
  }
}

class _LoadingField extends StatelessWidget {
  const _LoadingField({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
