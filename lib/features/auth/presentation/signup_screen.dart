import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    required this.repository,
  });

  final AuthRepo repository;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await widget.repository.signInWithGoogle();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (error) {
      _showMessage('Google sign-up failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showUsernameSignupComingSoon() {
    _showMessage('Username signup will be connected with Cloud Functions later.');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
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
                    'Username signup UI is ready. Backend will be added using Cloud Functions later.',
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

                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed:
                        _isLoading ? null : _showUsernameSignupComingSoon,
                    child: const Text('Sign up'),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Continue with Google'),
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