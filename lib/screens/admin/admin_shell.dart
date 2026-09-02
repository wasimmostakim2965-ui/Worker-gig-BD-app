import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'admin_deposits_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_users_screen.dart';
import 'admin_withdrawals_screen.dart';

/// Admin panel — mobile counterpart of the website's AdminLayout.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _pages = const [
    AdminDashboardScreen(),
    AdminDepositsScreen(),
    AdminWithdrawalsScreen(),
    AdminTasksScreen(),
    AdminUsersScreen(),
    AdminJobsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Stats'),
          NavigationDestination(
              icon: Icon(Icons.add_card),
              label: 'Deposits'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined),
              label: 'Payouts'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.work_outline),
              label: 'Jobs'),
        ],
      ),
    );
  }
}
