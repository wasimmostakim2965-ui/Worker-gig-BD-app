import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminWithdrawalsPage: approve/reject via
/// process_withdrawal_request RPC.
class AdminWithdrawalsScreen extends StatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  State<AdminWithdrawalsScreen> createState() =>
      _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends State<AdminWithdrawalsScreen> {
  List<WithdrawalRequest> _items = [];
  bool _loading = true;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('withdrawal_requests')
          .select('*, profiles(username, full_name, phone)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() =>
            _items = rows.map(WithdrawalRequest.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Admin withdrawals error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _process(WithdrawalRequest w, String action,
      {String note = ''}) async {
    final admin = context.read<AuthService>().profile;
    if (admin == null) return;
    setState(() => _busyId = w.id);
    try {
      await Supabase.instance.client
          .rpc('process_withdrawal_request', params: {
        'p_wd_id': w.id,
        'p_admin_uid': admin.id,
        'p_action': action,
        'p_note': note,
      });
      if (mounted) showSnack(context, 'Withdrawal ${action}d');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
    if (mounted) setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((w) => w.status == 'pending').toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Withdrawals (${pending.length} pending)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(
                  Icons.payments_outlined, 'No withdrawal requests')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final w = _items[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    w.user?.username ?? w.userId,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(w.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '${fmtMoney(w.amount)} via ${w.method}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.warning600)),
                            const SizedBox(height: 4),
                            Text('Account: ${w.accountNumber}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray600)),
                            if (w.status == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AppColors.success600,
                                        minimumSize:
                                            const Size.fromHeight(40),
                                      ),
                                      onPressed: _busyId == w.id
                                          ? null
                                          : () =>
                                              _process(w, 'approve'),
                                      icon: const Icon(Icons.check,
                                          size: 18),
                                      label: const Text('Approve'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            AppColors.error600,
                                        minimumSize:
                                            const Size.fromHeight(40),
                                      ),
                                      onPressed: _busyId == w.id
                                          ? null
                                          : () =>
                                              _process(w, 'reject'),
                                      icon: const Icon(Icons.close,
                                          size: 18),
                                      label: const Text('Reject'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
