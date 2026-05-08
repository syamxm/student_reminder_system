import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../data/auth_repo.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  AuthGate({super.key, AuthRepo? repository})
      : _repository = repository ?? AuthRepo();

  final AuthRepo _repository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _repository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = snapshot.data;

        if (user == null) {
          return LoginScreen(repository: _repository);
        }

        return DashboardScreen(
          user: user,
          repository: _repository,
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}