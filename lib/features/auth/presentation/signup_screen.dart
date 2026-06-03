import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'widgets/password_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.repository});

  final AuthRepo repository;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with WidgetsBindingObserver {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoading) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await widget.repository.signInWithGoogle();
    } catch (error) {
      _showMessage('Google sign-up failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  Future<void> _signUpWithUsername() async {
    final displayName = _displayNameController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (displayName.isEmpty) {
      _showMessage('Enter a display name.');
      return;
    }
    if (!_usernameRe.hasMatch(username)) {
      _showMessage('Username must be 3-20 letters, digits, or underscores.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.repository.signUpWithUsername(
        displayName: displayName,
        username: username,
        password: password,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      _showMessage('Sign-up failed: ${_errorText(error)}');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _errorText(Object error) => error is Exception
      ? error.toString().replaceFirst('Exception: ', '')
      : '$error';

  void _openLoginScreen() {
    Navigator.of(context).pop();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 72,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'Pick a username and password to get started.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: _displayNameController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _usernameController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),

                  PasswordField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: _isLoading ? null : _signUpWithUsername,
                    child: const Text('Sign up'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : _openLoginScreen,
                    child: const Text('Already have an account? Log in'),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 24),
                    const Center(child: CircularProgressIndicator()),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
