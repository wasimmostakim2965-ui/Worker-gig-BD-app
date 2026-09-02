import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import 'home_screen.dart';
import 'my_jobs_screen.dart';
import 'my_tasks_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Main dashboard with bottom navigation — the mobile counterpart of the
/// website's DashboardLayout sidebar.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  final _pages = const [
    HomeScreen(),
    MyTasksScreen(),
    MyJobsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;

    // Same gate as the website's AccountStatusGate.
    if (profile != null && profile.status == 'suspended') {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.warning50,
                  child: Icon(Icons.block,
                      color: AppColors.warning600, size: 32),
                ),
                const SizedBox(height: 16),
                Text('Account Suspended',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been suspended by an administrator. Posting jobs, withdrawals and other actions are disabled until your account is reactivated.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.gray600, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.read<AuthService>().signOut(),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work),
              label: 'Find Jobs'),
          NavigationDestination(
              icon: Icon(Icons.assignment_turned_in_outlined),
              selectedIcon: Icon(Icons.assignment_turned_in),
              label: 'My Tasks'),
          NavigationDestination(
              icon: Icon(Icons.business_center_outlined),
              selectedIcon: Icon(Icons.business_center),
              label: 'My Jobs'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}
