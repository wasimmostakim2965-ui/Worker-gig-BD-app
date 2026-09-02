import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Mirrors the website's SignupPage: optional referral code + Google sign-up.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _refCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final err = await context
        .read<AuthService>()
        .signInWithGoogle(referralCode: _refCtrl.text.trim());
    if (err != null && mounted) {
      setState(() {
        _error = err;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const WGLogo(size: 44),
                const SizedBox(height: 36),
                Text('Create your free account',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text(
                  'Start earning from today — join thousands of Bangladeshis earning money by completing simple online tasks.',
                  style: TextStyle(color: AppColors.gray600, height: 1.5),
                ),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  ErrorBox(_error!),
                  const SizedBox(height: 20),
                ],
                TextField(
                  controller: _refCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Referral Code (Optional)',
                    hintText: 'WGXXXXXXXX',
                    helperText: "Enter a friend's referral code to earn bonus",
                    prefixIcon: Icon(Icons.card_giftcard, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    foregroundColor: Colors.black87,
                  ),
                  onPressed: _loading ? null : _google,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata,
                          size: 28, color: Color(0xFF4285F4)),
                  label: const Text('Sign up with Google',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'By continuing you agree to the Terms of Service and Privacy Policy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
