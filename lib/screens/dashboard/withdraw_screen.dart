import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors WithdrawPage: gated by withdrawal_enabled + min_withdrawal
/// settings, submits via the request_withdrawal RPC (atomic balance hold).
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amount = TextEditingController();
  final _account = TextEditingController();

  List<WithdrawalRequest> _history = [];
  String _method = 'bkash';
  bool _enabled = false;
  double _minWithdraw = 1;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final db = Supabase.instance.client;
      final settings = await db.from('admin_settings').select();
      String val(String k, [String d = '']) => settings
          .firstWhere((s) => s['key'] == k, orElse: () => {'value': d})['value']
          .toString();
      _enabled = val('withdrawal_enabled') == 'true';
      _minWithdraw = double.tryParse(val('min_withdrawal', '1')) ?? 1;

      if (!mounted) return;
      final profile = context.read<AuthService>().profile;
      if (profile != null) {
        final rows = await db
            .from('withdrawal_requests')
            .select()
            .eq('user_id', profile.id)
            .order('created_at', ascending: false)
            .limit(20);
        _history = rows.map(WithdrawalRequest.fromJson).toList();
      }
    } catch (e) {
      debugPrint('Withdraw load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount < _minWithdraw) {
      setState(() =>
          _error = 'Minimum withdrawal is ${fmtMoney(_minWithdraw)}.');
      return;
    }
    if (amount > profile.earningBalance) {
      setState(() => _error = 'Insufficient earning balance.');
      return;
    }
    if (_account.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid account number.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.rpc('request_withdrawal', params: {
        'p_uid': profile.id,
        'p_amount': amount,
        'p_method': _method,
        'p_account': _account.text.trim(),
      });
      if (mounted) {
        showSnack(context, 'Withdrawal request submitted!');
        _amount.clear();
        _account.clear();
        context.read<AuthService>().refreshProfile();
        _load();
      }
    } catch (e) {
      setState(() => _error = '$e');
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Withdraw')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Earning Balance',
                              style: TextStyle(color: AppColors.gray600)),
                          Text(fmtMoney(profile?.earningBalance),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: AppColors.earnGreen)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_enabled)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Withdrawals are currently disabled. Please try again later.',
                          style: TextStyle(color: AppColors.warning600),
                        ),
                      ),
                    )
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: ['bkash', 'nagad', 'rocket']
                                  .map((m) => Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Center(
                                                child: Text(m == 'bkash'
                                                    ? 'bKash'
                                                    : m == 'nagad'
                                                        ? 'Nagad'
                                                        : 'Rocket')),
                                            selected: _method == m,
                                            onSelected: (_) => setState(
                                                () => _method = m),
                                            selectedColor:
                                                AppColors.primary600,
                                            labelStyle: TextStyle(
                                              color: _method == m
                                                  ? Colors.white
                                                  : AppColors.gray600,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: InputDecoration(
                                labelText: 'Amount (USD)',
                                helperText:
                                    'Minimum ${fmtMoney(_minWithdraw)}',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _account,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Account Number',
                                  hintText: '01XXXXXXXXX'),
                            ),
                            const SizedBox(height: 12),
                            if (_error != null) ...[
                              ErrorBox(_error!),
                              const SizedBox(height: 12),
                            ],
                            FilledButton(
                              onPressed: _submitting ? null : _submit,
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Request Withdrawal'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Withdrawal History',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    const Text('No withdrawals yet.',
                        style: TextStyle(color: AppColors.gray500))
                  else
                    ..._history.map((w) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(fmtMoney(w.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${w.method} • ${w.accountNumber}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: StatusBadge(w.status),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
