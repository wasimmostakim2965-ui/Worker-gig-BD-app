import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';
import 'auth/signup_screen.dart';

/// Mirrors the website's LandingPage: hero, features, how-it-works,
/// categories, and the centered Google sign-up CTA.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  List<String> _categories = [];
  bool _googleLoading = false;
  String? _error;

  static const _features = [
    (Icons.account_balance_wallet_outlined, 'Easy Deposits & Withdrawals',
        'bKash, Nagad, Rocket — deposit and withdraw your earnings easily with low fees.'),
    (Icons.shield_outlined, 'Secure & Trusted',
        'Every transaction is protected. Admin-verified deposits and withdrawals keep your money safe.'),
    (Icons.trending_up, 'Unlimited Earning Potential',
        'Complete tasks, post jobs, refer friends, and run ads — multiple income streams in one platform.'),
    (Icons.bolt_outlined, 'Fast Task Completion',
        'Quick, simple micro-tasks that take minutes. Like, follow, subscribe, watch, and earn.'),
    (Icons.people_outline, 'Growing Community',
        'Join Bangladeshi freelancers earning online from home.'),
    (Icons.bar_chart, 'Detailed Analytics',
        'Track your earnings, task completion rate, and growth with a powerful dashboard.'),
  ];

  static const _steps = [
    ('01', 'Create Your Account',
        'Sign up for free with just your Google account. No verification hassle.'),
    ('02', 'Choose & Complete Tasks',
        'Browse 45+ task categories, pick what you like, complete it, and submit proof.'),
    ('03', 'Get Your Earnings',
        'Withdraw your earnings to bKash, Nagad, or Rocket once you reach the minimum amount.'),
  ];

  @override
  void initState() {
    super.initState();
    Supabase.instance.client
        .from('categories')
        .select('name')
        .eq('is_active', true)
        .order('display_order')
        .then((rows) {
      if (mounted) {
        setState(() =>
            _categories = rows.map((c) => c['name'].toString()).toList());
      }
    }).catchError((_) {});
  }

  Future<void> _googleSignUp() async {
    setState(() {
      _error = null;
      _googleLoading = true;
    });
    final err = await context.read<AuthService>().signInWithGoogle();
    if (err != null && mounted) {
      setState(() {
        _error = err;
        _googleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const WGLogo(size: 34),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen())),
            child: const Text('Login'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SignupScreen())),
              child: const Text('Get Started'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ---- Hero ----
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary50, Colors.white],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      border: Border.all(color: AppColors.primary100),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            size: 8, color: AppColors.primary600),
                        SizedBox(width: 8),
                        Text(
                          'Trusted Micro-Task Platform in Bangladesh',
                          style: TextStyle(
                              color: AppColors.primary700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Earn Money Doing\nSimple Tasks',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 34, height: 1.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Like, follow, subscribe, watch videos, complete surveys, and more. Join Bangladeshis earning online from the comfort of home.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15, height: 1.6, color: AppColors.gray600),
                  ),
                  const SizedBox(height: 32),
                  if (_error != null) ...[
                    ErrorBox(_error!),
                    const SizedBox(height: 16),
                  ],
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(260, 54),
                      side: const BorderSide(color: AppColors.gray200),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      foregroundColor: AppColors.gray900,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    onPressed: _googleLoading ? null : _googleSignUp,
                    icon: _googleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.g_mobiledata,
                            size: 28, color: Color(0xFF4285F4)),
                    label: const Text('Sign up with Google'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginScreen())),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TrustChip(Icons.check_circle, 'Secure payments'),
                      SizedBox(width: 16),
                      _TrustChip(Icons.public, 'Available nationwide'),
                    ],
                  ),
                ],
              ),
            ),

            // ---- Features ----
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('Why Choose WORKER GIG BD?',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  const Text(
                      'Everything you need to earn online, in one place',
                      style: TextStyle(color: AppColors.gray500)),
                  const SizedBox(height: 24),
                  ..._features.map((f) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary50,
                            child: Icon(f.$1, color: AppColors.primary600),
                          ),
                          title: Text(f.$2,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(f.$3),
                        ),
                      )),
                ],
              ),
            ),

            // ---- How it works ----
            Container(
              width: double.infinity,
              color: AppColors.gray50,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('How It Works',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  ..._steps.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$1,
                                style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary600)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.$2,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(s.$3,
                                      style: const TextStyle(
                                          color: AppColors.gray600,
                                          height: 1.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // ---- Categories ----
            if (_categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Task Categories',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories
                          .map((c) => Chip(
                                label: Text(c,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: AppColors.primary50,
                                side: BorderSide.none,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

            // ---- CTA ----
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary700, AppColors.primary950],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('Ready to Start Earning?',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text(
                    'Join thousands of Bangladeshis earning online today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.primary100),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary700),
                    onPressed: _googleSignUp,
                    child: const Text('Sign up with Google'),
                  ),
                ],
              ),
            ),

            // ---- Footer ----
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text('workergigbd.site',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray600)),
                  const SizedBox(height: 4),
                  const Text(
                    'wasimmostakim2965@gmail.com\nWhatsApp: +880 1338-882758',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.gray500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TrustChip(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.success600),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(fontSize: 12, color: AppColors.gray600)),
      ],
    );
  }
}
