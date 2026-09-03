import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors DepositHistoryPage.tsx — a dedicated list of my deposit_requests.
class DepositHistoryScreen extends StatefulWidget {
  const DepositHistoryScreen({super.key});

  @override
  State<DepositHistoryScreen> createState() => _DepositHistoryScreenState();
}

class _DepositHistoryScreenState extends State<DepositHistoryScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    try {
      final rows = await auth.client
          .from('deposit_requests')
          .select()
          .eq('user_id', auth.profile!.id)
          .order('created_at', ascending: false)
          .limit(100);
      _rows = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _rows.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long,
                  title: 'No deposits yet',
                  subtitle: 'Your deposit requests will appear here.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rows.length,
                    itemBuilder: (context, i) {
                      final r = _rows[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet,
                              color: AppColors.primary600),
                          title: Text(
                              '৳${(r['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(
                            '${r['method'] ?? ''} • ${r['transaction_id'] ?? ''}\n${fmtDate(r['created_at'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: StatusBadge(r['status'] ?? 'pending'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
