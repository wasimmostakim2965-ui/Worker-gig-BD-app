import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdminDepositsPage: review deposit requests and
/// approve/reject via the process_deposit RPC.
class AdminDepositsScreen extends StatefulWidget {
  const AdminDepositsScreen({super.key});

  @override
  State<AdminDepositsScreen> createState() => _AdminDepositsScreenState();
}

class _AdminDepositsScreenState extends State<AdminDepositsScreen> {
  List<DepositRequest> _items = [];
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
          .from('deposit_requests')
          .select('*, profiles(username, full_name, phone)')
          .order('created_at', ascending: false)
          .limit(100);
      if (mounted) {
        setState(() =>
            _items = rows.map(DepositRequest.fromJson).toList());
      }
    } catch (e) {
      debugPrint('Admin deposits error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _process(DepositRequest d, String action,
      {String note = ''}) async {
    final admin = context.read<AuthService>().profile;
    if (admin == null) return;
    setState(() => _busyId = d.id);
    try {
      await Supabase.instance.client.rpc('process_deposit', params: {
        'p_deposit_id': d.id,
        'p_admin_uid': admin.id,
        'p_action': action,
        'p_note': note,
      });
      if (mounted) showSnack(context, 'Deposit ${action}d');
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
    if (mounted) setState(() => _busyId = null);
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((d) => d.status == 'pending').toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('Deposits (${pending.length} pending)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const LoadingView()
          : _items.isEmpty
              ? const EmptyView(Icons.add_card, 'No deposit requests')
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final d = _items[i];
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
                                    d.user?.username ?? d.userId,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                StatusBadge(d.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                '${fmtMoney(d.amount)} via ${d.method}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.primary700)),
                            const SizedBox(height: 4),
                            Text(
                                'From: ${d.senderNumber}\nTrxID: ${d.transactionId}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray600)),
                            if (d.status == 'pending') ...[
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
                                      onPressed: _busyId == d.id
                                          ? null
                                          : () =>
                                              _process(d, 'approve'),
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
                                      onPressed: _busyId == d.id
                                          ? null
                                          : () =>
                                              _process(d, 'reject'),
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
