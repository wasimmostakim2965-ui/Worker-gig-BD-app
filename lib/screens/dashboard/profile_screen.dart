import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth/admin_login_screen.dart';
import 'deposit_screen.dart';
import 'post_job_screen.dart';
import 'share_earn_screen.dart';
import 'withdraw_screen.dart';

/// Mirrors ProfilePage + the DashboardLayout sidebar links: balances,
/// account stats, profile editing, and navigation to the money screens.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _editProfile() async {
    final auth = context.read<AuthService>();
    final profile = auth.profile;
    if (profile == null) return;
    final nameCtrl = TextEditingController(text: profile.fullName);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved == true) {
      try {
        await Supabase.instance.client.from('profiles').update({
          'full_name': nameCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
        }).eq('id', profile.id);
        await auth.refreshProfile();
        if (mounted) showSnack(context, 'Profile updated');
      } catch (e) {
        if (mounted) showSnack(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final p = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: p == null
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary100,
                          backgroundImage: p.avatarUrl.isNotEmpty
                              ? NetworkImage(p.avatarUrl)
                              : null,
                          child: p.avatarUrl.isEmpty
                              ? Text(
                                  (p.username.isNotEmpty
                                          ? p.username[0]
                                          : 'U')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary700),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      p.fullName.isNotEmpty
                                          ? p.fullName
                                          : p.username,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (p.isVerified) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified,
                                        size: 16,
                                        color: AppColors.primary600),
                                  ],
                                  if (p.premiumActive) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.workspace_premium,
                                        size: 16,
                                        color: AppColors.accent500),
                                  ],
                                ],
                              ),
                              Text('@${p.username}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.gray500)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: _editProfile,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _balanceCard('Earning', p.earningBalance,
                        AppColors.earnGreen),
                    const SizedBox(width: 12),
                    _balanceCard('Deposit', p.depositBalance,
                        AppColors.primary600),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('${p.tasksCompleted}', 'Tasks'),
                        _stat('${p.jobsPosted}', 'Jobs'),
                        _stat(fmtMoney(p.totalEarned), 'Earned'),
                        _stat(fmtMoney(p.totalWithdraw), 'Withdrawn'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _menuItem(Icons.add_card, 'Deposit',
                    'Add money to your deposit balance', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DepositScreen()));
                }),
                _menuItem(Icons.payments_outlined, 'Withdraw',
                    'Cash out your earnings', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WithdrawScreen()));
                }),
                _menuItem(Icons.campaign_outlined, 'Post a Job',
                    'Get workers to complete your task', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PostJobScreen()));
                }),
                _menuItem(Icons.share_outlined, 'Share & Earn',
                    'Invite friends and earn referral bonus', () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ShareEarnScreen()));
                }),
                if (p.isAdmin)
                  _menuItem(Icons.admin_panel_settings_outlined,
                      'Admin Panel', 'Manage users, deposits, withdrawals',
                      () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen()));
                  }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error600,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.error100),
                  ),
                  onPressed: () => auth.signOut(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Sign Out'),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _balanceCard(String label, double amount, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.gray500)),
              const SizedBox(height: 4),
              Text(fmtMoney(amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.gray500)),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle,
      VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary50,
          child: Icon(icon, color: AppColors.primary600, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right,
            color: AppColors.gray500),
        onTap: onTap,
      ),
    );
  }
}
