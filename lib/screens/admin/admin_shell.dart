import 'package:flutter/material.dart';

import '../../theme.dart';
import 'admin_ads_screen.dart';
import 'admin_categories_screen.dart';
import 'admin_chat_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_deposits_screen.dart';
import 'admin_jobs_screen.dart';
import 'admin_reports_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_tickets_screen.dart';
import 'admin_users_screen.dart';
import 'admin_verifications_screen.dart';
import 'admin_withdrawals_screen.dart';

/// Admin panel — mobile counterpart of the website's AdminLayout.
/// Bottom nav has the core sections; a Drawer lists every admin section,
/// exactly like the web sidebar.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  final _titles = const [
    'Dashboard',
    'Deposits',
    'Withdrawals',
    'Tasks',
    'Users',
    'Jobs'
  ];
  final _pages = const [
    AdminDashboardScreen(),
    AdminDepositsScreen(),
    AdminWithdrawalsScreen(),
    AdminTasksScreen(),
    AdminUsersScreen(),
    AdminJobsScreen(),
  ];

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _item(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary600, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context); // close drawer
        onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_index])),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: AppColors.primary600, size: 28),
                    SizedBox(width: 10),
                    Text('Admin Sections',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ],
                ),
              ),
              const Divider(),
              _item(context, Icons.verified_user, 'Verifications',
                  () => _open(const AdminVerificationsScreen())),
              _item(context, Icons.support_agent, 'Tickets',
                  () => _open(const AdminTicketsScreen())),
              _item(context, Icons.forum, 'Live Chat',
                  () => _open(const AdminChatScreen())),
              _item(context, Icons.flag_outlined, 'Reports',
                  () => _open(const AdminReportsScreen())),
              _item(context, Icons.campaign, 'Ad Banners',
                  () => _open(const AdminAdsScreen())),
              _item(context, Icons.category_outlined, 'Categories',
                  () => _open(const AdminCategoriesScreen())),
              _item(context, Icons.settings, 'Settings',
                  () => _open(const AdminSettingsScreen())),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Core sections are in the bottom bar.',
                    style: TextStyle(fontSize: 12, color: AppColors.gray500)),
              ),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.add_card), label: 'Deposits'),
          NavigationDestination(
              icon: Icon(Icons.payments_outlined), label: 'Payouts'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users'),
          NavigationDestination(
              icon: Icon(Icons.work_outline), label: 'Jobs'),
        ],
      ),
    );
  }
}
