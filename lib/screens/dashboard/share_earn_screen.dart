import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors ShareEarnPage: referral code + share link + referral stats.
class ShareEarnScreen extends StatefulWidget {
  const ShareEarnScreen({super.key});

  @override
  State<ShareEarnScreen> createState() => _ShareEarnScreenState();
}

class _ShareEarnScreenState extends State<ShareEarnScreen> {
  String _bonus = '';
  int _referralCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = Supabase.instance.client;
      final settings = await db.from('admin_settings').select();
      final bonus = settings.firstWhere(
        (s) => s['key'] == 'referral_bonus',
        orElse: () => {'value': ''},
      )['value'];
      if (!mounted) return;
      final profile = context.read<AuthService>().profile;
      var count = 0;
      if (profile != null) {
        final rows = await db
            .from('referrals')
            .select('id')
            .eq('referrer_id', profile.id);
        count = rows.length;
      }
      if (mounted) {
        setState(() {
          _bonus = bonus.toString();
          _referralCount = count;
        });
      }
    } catch (e) {
      debugPrint('Share earn load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthService>().profile;
    final code = profile?.referralCode ?? '';
    final link = 'https://www.workergigbd.site/signup?ref=$code';

    return Scaffold(
      appBar: AppBar(title: const Text('Share & Earn')),
      body: _loading
          ? const LoadingView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary700, AppColors.primary950],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Invite Friends, Earn Bonus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (_bonus.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Earn \$$_bonus for every friend who joins!',
                          style: const TextStyle(color: AppColors.primary100),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Referral Code',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.gray100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: code));
                                showSnack(context, 'Code copied');
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () async {
                            try {
                              await SharePlus.instance.share(
                                ShareParams(
                                  text:
                                      'Join WORKER GIG BD and earn money online! Use my referral code $code: $link',
                                ),
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share Referral Link'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.success50,
                      child: Icon(Icons.people, color: AppColors.success600),
                    ),
                    title: const Text(
                      'Total Referrals',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: Text(
                      '$_referralCount',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
