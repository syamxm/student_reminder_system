import 'package:flutter/material.dart';

import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'package:student_reminder_system/features/auth/presentation/widgets/password_field.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.repository,
    required this.authProvider,
  });

  final AuthRepo repository;
  final String authProvider;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();

  bool _isDeleting = false;
  String? _error;

  bool get _isUsername => widget.authProvider == 'username';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _controller.text;

    if (_isUsername) {
      if (input.isEmpty) {
        setState(() => _error = 'Enter your password to confirm.');
        return;
      }
    } else if (input.trim() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.');
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await widget.repository.deleteAccount(password: input);
      // On success the user is signed out; AuthGate navigates to login and
      // tears this screen down, so no further navigation is needed here.
    } catch (error) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _error = error is Exception
              ? error.toString().replaceFirst('Exception: ', '')
              : '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: const Text('Delete Account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account and all your data. '
            'This cannot be undone.',
          ),
          const SizedBox(height: 16),
          if (_isUsername)
            PasswordField(
              controller: _controller,
              enabled: !_isDeleting,
              labelText: 'Password',
            )
          else
            TextField(
              controller: _controller,
              enabled: !_isDeleting,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: error),
          child: Text(_isDeleting ? 'Deleting...' : 'Delete'),
        ),
      ],
    );
  }
}
