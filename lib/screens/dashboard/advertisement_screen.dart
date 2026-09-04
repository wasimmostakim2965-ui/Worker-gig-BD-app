import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors AdvertisementPage.tsx: creates ads through the create_ad RPC
/// (budget is deducted from deposit_balance atomically) and lists my ads.
class AdvertisementScreen extends StatefulWidget {
  const AdvertisementScreen({super.key});

  @override
  State<AdvertisementScreen> createState() => _AdvertisementScreenState();
}

class _AdvertisementScreenState extends State<AdvertisementScreen> {
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _imageUrl = TextEditingController();
  final _budget = TextEditingController();
  bool _busy = false;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _ads = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthService>();
    try {
      final rows = await auth.client
          .from('advertisements')
          .select()
          .eq('user_id', auth.profile!.id)
          .order('created_at', ascending: false)
          .limit(50);
      _ads = List<Map<String, dynamic>>.from(rows);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _create() async {
    final auth = context.read<AuthService>();
    final profile = auth.profile;
    if (profile == null) return;
    final budget = double.tryParse(_budget.text.trim()) ?? 0;
    if (_title.text.trim().isEmpty || _url.text.trim().isEmpty) {
      setState(() => _error = 'Title and URL are required.');
      return;
    }
    if (budget <= 0) {
      setState(() => _error = 'Please enter a valid budget amount.');
      return;
    }
    if (profile.depositBalance < budget) {
      setState(() => _error =
          'Insufficient deposit balance. You need ৳${budget.toStringAsFixed(2)} but have ৳${profile.depositBalance.toStringAsFixed(2)}.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await auth.client.rpc('create_ad', params: {
        'p_uid': profile.id,
        'p_title': _title.text.trim(),
        'p_url': _url.text.trim(),
        'p_image_url': _imageUrl.text.trim(),
        'p_budget': budget,
      });
      await auth.refreshProfile();
      _title.clear();
      _url.clear();
      _imageUrl.clear();
      _budget.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ad created! It will go live after admin approval.')));
        setState(() => _loading = true);
        _load();
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
      appBar: AppBar(title: const Text('Advertise')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create an Ad',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                              'Deposit balance: ৳${(profile?.depositBalance ?? 0).toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.gray500)),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _title,
                              decoration:
                                  const InputDecoration(labelText: 'Ad title')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _url,
                              decoration:
                                  const InputDecoration(labelText: 'Target URL')),
                          const SizedBox(height: 12),
                          TextField(
                              controller: _imageUrl,
                              decoration: const InputDecoration(
                                  labelText: 'Image URL (optional)')),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _budget,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                                const InputDecoration(labelText: 'Budget (৳)'),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(
                                    color: AppColors.danger600, fontSize: 13)),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _create,
                              child: Text(_busy ? 'Creating...' : 'Create Ad'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('My Ads', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_ads.isEmpty)
                    const EmptyState(
                        icon: Icons.campaign,
                        title: 'No advertisements',
                        subtitle: 'Create your first ad above.')
                  else
                    ..._ads.map((ad) => Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((ad['image_url'] ?? '').toString().isNotEmpty)
                                Image.network(ad['image_url'],
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const SizedBox.shrink()),
                              ListTile(
                                title: Text(ad['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    'Budget: ৳${fmt2(ad['budget'])} • Clicks: ${ad['clicks'] ?? 0}',
                                    style: const TextStyle(fontSize: 12)),
                                trailing:
                                    StatusBadge(ad['status'] ?? 'pending'),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}
