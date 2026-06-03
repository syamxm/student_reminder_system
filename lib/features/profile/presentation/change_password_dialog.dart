import 'package:flutter/material.dart';

import 'package:student_reminder_system/features/auth/data/auth_repo.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key, required this.repository});

  final AuthRepo repository;

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _oldController = TextEditingController();
  final _newController = TextEditingController();

  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _oldController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final oldPassword = _oldController.text;
    final newPassword = _newController.text;

    if (newPassword.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await widget.repository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _oldController,
            enabled: !_isSaving,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newController,
            enabled: !_isSaving,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
