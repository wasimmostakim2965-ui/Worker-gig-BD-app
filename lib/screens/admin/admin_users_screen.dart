import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminUsersPage: search_users RPC + status/verify/premium/balance
/// management through the same RPCs the web admin uses.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _search = TextEditingController();
  List<Profile> _users = [];
  bool _loading = true;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final term = _search.text.trim();
      final List<dynamic> rows;
      if (term.isNotEmpty) {
        rows = await _db.rpc('search_users', params: {'p_term': term}) as List;
      } else {
        rows = await _db
            .from('profiles')
            .select()
            .neq('status', 'admin')
            .order('created_at', ascending: false)
            .limit(100);
      }
      if (mounted) {
        setState(() => _users = rows
            .map((e) => Profile.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList());
      }
    } catch (e) {
      debugPrint('Admin users error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _rpc(String name, Map<String, dynamic> params,
      String successMsg) async {
    try {
      await _db.rpc(name, params: params);
      if (mounted) showSnack(context, successMsg);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  Future<void> _adjustBalance(Profile u) async {
    final ctrl = TextEditingController();
    final delta = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Adjust balance — ${u.username}'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: const InputDecoration(
              labelText: 'Earning balance change',
              hintText: 'e.g. 5 or -2.5'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, double.tryParse(ctrl.text)),
              child: const Text('Apply')),
        ],
      ),
    );
    if (delta == null || delta == 0) return;
    await _rpc('adjust_user_balance', {
      'p_user_uid': u.id,
      'p_earning_delta': delta,
      'p_deposit_delta': 0,
      'p_reason': 'Admin earning adjustment by ${u.username}',
    }, 'Balance adjusted');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search by username, email, phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: _load,
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _users.isEmpty
                    ? const EmptyView(Icons.people_outline, 'No users found')
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final u = _users[i];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Flexible(
                                                child: Text(u.username,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700),
                                                    overflow: TextOverflow
                                                        .ellipsis),
                                              ),
                                              if (u.isVerified) ...[
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified,
                                                    size: 14,
                                                    color: AppColors
                                                        .primary600),
                                              ],
                                              if (u.isPremium) ...[
                                                const SizedBox(width: 4),
                                                const Icon(
                                                    Icons.workspace_premium,
                                                    size: 14,
                                                    color:
                                                        AppColors.accent500),
                                              ],
                                            ],
                                          ),
                                        ),
                                        StatusBadge(u.status),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Earn: ${fmtMoney(u.earningBalance)} • Deposit: ${fmtMoney(u.depositBalance)} • Tasks: ${u.tasksCompleted}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray600),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _action(
                                          u.status == 'suspended'
                                              ? 'Activate'
                                              : 'Suspend',
                                          Icons.block,
                                          () => _rpc('set_user_status', {
                                            'p_user_uid': u.id,
                                            'p_status':
                                                u.status == 'suspended'
                                                    ? 'active'
                                                    : 'suspended',
                                          }, 'Status updated'),
                                        ),
                                        _action(
                                          u.isVerified
                                              ? 'Unverify'
                                              : 'Verify',
                                          Icons.verified_outlined,
                                          () => _rpc('set_user_verified', {
                                            'p_user_uid': u.id,
                                            'p_verified': !u.isVerified,
                                          }, 'Verification updated'),
                                        ),
                                        _action(
                                          'Premium 30d',
                                          Icons.workspace_premium_outlined,
                                          () => _rpc('set_user_premium', {
                                            'p_user_uid': u.id,
                                            'p_days': 30,
                                          }, 'Premium granted'),
                                        ),
                                        _action(
                                          'Balance',
                                          Icons.account_balance_wallet_outlined,
                                          () => _adjustBalance(u),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback onTap) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(fontSize: 12),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: Text(label),
    );
  }
}
