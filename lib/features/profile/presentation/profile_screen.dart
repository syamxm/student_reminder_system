import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/profile_repo.dart';
import '../data/user_profile_model.dart';
import 'package:student_reminder_system/core/semester_engine.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});

  final User user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ProfileRepo();

  final _campusController = TextEditingController();
  final _facultyController = TextEditingController();

  String? _selectedSemester;
  bool _isLoading = true;
  bool _isSaving = false;

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

    if (profile != null) {
      _campusController.text = profile.campus ?? '';
      _facultyController.text = profile.faculty ?? '';
      _selectedSemester = profile.activeSemester;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() => _isSaving = true);

    try {
      final profile = UserProfileModel(
        uid: widget.user.uid,
        email: widget.user.email ?? '',
        displayName: widget.user.displayName ?? '',
        campus: _campusController.text.trim().isEmpty
            ? null
            : _campusController.text.trim(),
        faculty: _facultyController.text.trim().isEmpty
            ? null
            : _facultyController.text.trim(),
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

                  TextFormField(
                    controller: _campusController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Campus',
                      hintText: 'e.g. Shah Alam',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _facultyController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Faculty',
                      hintText: 'e.g. Faculty of Computer and Mathematical Sciences',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedSemester,
                    decoration: const InputDecoration(
                      labelText: 'Active Semester',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('None'),
                      ),
                      ...semesterStartDates.keys.map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Text(semesterLabels[code] ?? code),
                        );
                      }),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) => setState(() => _selectedSemester = value),
                  ),

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
}
