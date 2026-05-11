import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:student_reminder_system/features/auth/data/auth_repo.dart';
import 'package:student_reminder_system/features/dashboard/presentation/tabs/home_tab.dart';
import 'package:student_reminder_system/features/dashboard/presentation/tabs/profile_tab.dart';
import 'package:student_reminder_system/features/dashboard/presentation/tabs/reminders_tab.dart';
import 'package:student_reminder_system/features/dashboard/presentation/tabs/timetable_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.repository,
  });

  final User user;
  final AuthRepo repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeTab(user: widget.user),
      const RemindersTab(),
      const TimetableTab(),
      ProfileTab(user: widget.user, repository: widget.repository),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_selectedIndex)),
        actions: [
          if (_selectedIndex != 3)
            IconButton(
              tooltip: 'Profile',
              onPressed: () {
                setState(() {
                  _selectedIndex = 3;
                });
              },
              icon: const Icon(Icons.account_circle_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt_rounded),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _titleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Reminders';
      case 2:
        return 'Timetable';
      case 3:
        return 'Profile';
      case 0:
      default:
        return 'Dashboard';
    }
  }
}
