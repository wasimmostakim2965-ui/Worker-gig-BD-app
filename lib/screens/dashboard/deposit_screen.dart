import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors DepositPage: payment numbers come from admin_settings,
/// deposits are inserted into deposit_requests for admin review.
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _PaymentMethod {
  final String id;
  final String name;
  final String number;
  final bool enabled;
  const _PaymentMethod(this.id, this.name, this.number, this.enabled);
}

class _DepositScreenState extends State<DepositScreen> {
  final _amount = TextEditingController();
  final _sender = TextEditingController();
  final _trx = TextEditingController();

  List<_PaymentMethod> _methods = [];
  List<DepositRequest> _history = [];
  String _method = 'bkash';
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

      if (!mounted) return;
      final profile = context.read<AuthService>().profile;
      _methods = [
        _PaymentMethod('bkash', 'bKash', val('payment_bkash'),
            val('payment_bkash_enabled', 'true') != 'false'),
        _PaymentMethod('nagad', 'Nagad', val('payment_nagad'),
            val('payment_nagad_enabled') == 'true'),
        _PaymentMethod('rocket', 'Rocket', val('payment_rocket'),
            val('payment_rocket_enabled') == 'true'),
      ].where((m) => m.enabled).toList();
      if (_methods.isNotEmpty) _method = _methods.first.id;

      if (profile != null) {
        final rows = await db
            .from('deposit_requests')
            .select()
            .eq('user_id', profile.id)
            .order('created_at', ascending: false)
            .limit(20);
        _history = rows.map(DepositRequest.fromJson).toList();
      }
    } catch (e) {
      debugPrint('Deposit load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final profile = context.read<AuthService>().profile;
    if (profile == null) return;
    final amount = double.tryParse(_amount.text) ?? 0;
    if (amount <= 0) {
      setState(() => _error = 'Enter a valid amount.');
      return;
    }
    if (_sender.text.trim().isEmpty || _trx.text.trim().isEmpty) {
      setState(() => _error = 'Sender number and Transaction ID are required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.from('deposit_requests').insert({
        'user_id': profile.id,
        'amount': amount,
        'method': _method,
        'sender_number': _sender.text.trim(),
        'transaction_id': _trx.text.trim(),
      });
      if (mounted) {
        showSnack(context, 'Deposit request submitted! Wait for admin approval.');
        _amount.clear();
        _sender.clear();
        _trx.clear();
        _load();
      }
    } catch (e) {
      setState(() => _error = '$e');
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _methods.where((m) => m.id == _method).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Deposit')),
      body: _loading
          ? const LoadingView()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_methods.isEmpty)
                    const EmptyView(Icons.payments_outlined,
                        'Deposits are currently unavailable')
                  else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Payment Method',
                                style:
                                    TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Row(
                              children: _methods
                                  .map((m) => Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: ChoiceChip(
                                            label: Center(child: Text(m.name)),
                                            selected: _method == m.id,
                                            onSelected: (_) => setState(
                                                () => _method = m.id),
                                            selectedColor:
                                                AppColors.primary600,
                                            labelStyle: TextStyle(
                                              color: _method == m.id
                                                  ? Colors.white
                                                  : AppColors.gray600,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                            if (selected != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Cash Out করুন এই নম্বরে:',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.gray500)),
                                          Text(
                                            selected.number.isEmpty
                                                ? 'Contact support'
                                                : selected.number,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 16,
                                                color: AppColors.primary700),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selected.number.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () {
                                          Clipboard.setData(ClipboardData(
                                              text: selected.number));
                                          showSnack(context,
                                              'Number copied');
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextField(
                              controller: _amount,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Amount (USD)',
                                  hintText: '0.00'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _sender,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                  labelText: 'Sender Number',
                                  hintText: '01XXXXXXXXX'),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _trx,
                              decoration: const InputDecoration(
                                  labelText: 'Transaction ID (TrxID)'),
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
                                  : const Text('Submit Deposit'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text('Deposit History',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  if (_history.isEmpty)
                    const Text('No deposits yet.',
                        style: TextStyle(color: AppColors.gray500))
                  else
                    ..._history.map((d) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(fmtMoney(d.amount),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${d.method} • ${d.transactionId}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: StatusBadge(d.status),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
