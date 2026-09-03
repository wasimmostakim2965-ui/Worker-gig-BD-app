import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors PremiumPage.tsx: reads premium_price / premium_duration_days /
/// premium_enabled from admin_settings and calls the subscribe_premium RPC.
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  double _price = 500;
  int _days = 30;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final client = context.read<AuthService>().client;
    try {
      final rows = await client.from('admin_settings').select('key, value');
      for (final r in rows) {
        if (r['key'] == 'premium_price') {
          _price = double.tryParse('${r['value']}') ?? 500;
        }
        if (r['key'] == 'premium_duration_days') {
          _days = int.tryParse('${r['value']}') ?? 30;
        }
        if (r['key'] == 'premium_enabled') {
          _enabled = '${r['value']}' == 'true';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _subscribe() async {
    final auth = context.read<AuthService>();
    final profile = auth.profile;
    if (profile == null) return;
    if (profile.depositBalance < _price) {
      setState(() => _error =
          'Insufficient deposit balance. You need ৳${_price.toStringAsFixed(0)} but have ৳${profile.depositBalance.toStringAsFixed(2)}.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.client.rpc('subscribe_premium', params: {'p_uid': profile.id});
      await auth.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Premium activated! Enjoy your benefits.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Premium Membership')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.workspace_premium,
                            size: 48, color: AppColors.accent500),
                        const SizedBox(height: 8),
                        Text('Premium Member',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('$_days days for ৳${_price.toStringAsFixed(0)}',
                            style: const TextStyle(color: AppColors.gray500)),
                        const SizedBox(height: 16),
                        _benefit(Icons.check_circle, 'Access to premium-only jobs'),
                        _benefit(Icons.check_circle, 'Premium badge on your profile'),
                        _benefit(Icons.check_circle, 'Priority in the job feed'),
                        const SizedBox(height: 16),
                        if (profile != null && profile.premiumActive)
                          const StatusBadge('active')
                        else if (!_enabled)
                          const Text('Premium is currently disabled.',
                              style: TextStyle(color: AppColors.gray500))
                        else ...[
                          if (_error != null) ...[
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.danger600, fontSize: 13)),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _subscribe,
                              child: Text(_busy
                                  ? 'Processing...'
                                  : 'Buy Premium — ৳${_price.toStringAsFixed(0)}'),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text('Deducted from your deposit balance.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.gray500)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _benefit(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.earnGreen),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}
