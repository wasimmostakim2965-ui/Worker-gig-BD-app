import 'package:flutter/material.dart';

import 'oauth_webview_screen.dart';
import '../../widgets/common.dart';
import 'signup_screen.dart';

/// Mirrors the website's LoginPage: Google sign-in.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _google() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    // Open Google sign-in INSIDE the app — never the external browser.
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const OAuthWebViewScreen()),
    );
    if (ok != true && mounted) {
      setState(() {
        _error = 'Sign-in was not completed.';
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
                Text('Welcome back',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen())),
                      child: const Text('Sign up',
                          style: TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  ErrorBox(_error!),
                  const SizedBox(height: 20),
                ],
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
                  label: const Text('Continue with Google',
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
