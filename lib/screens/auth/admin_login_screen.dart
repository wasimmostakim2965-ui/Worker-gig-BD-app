import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../admin/admin_shell.dart';

/// Mirrors the website's AdminGatePage: single shared admin account,
/// unlocked with the password only. Verifies profile.status == 'admin'
/// before opening the panel, exactly like the web flow.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    final auth = context.read<AuthService>();
    final err = await auth.signInWithPassword(
        AppConfig.adminEmail, _passCtrl.text);
    if (err != null) {
      setState(() {
        _error = err;
        _loading = false;
      });
      return;
    }
    await auth.refreshProfile();
    if (!mounted) return;
    if (auth.profile?.status != 'admin') {
      await auth.signOut();
      setState(() {
        _error = 'This password does not unlock the admin panel.';
        _loading = false;
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const WGLogo(size: 44),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary50,
                          child: Icon(Icons.admin_panel_settings,
                              color: AppColors.primary600),
                        ),
                        const SizedBox(height: 14),
                        Text('Admin Access',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        const Text('Enter the admin password to continue',
                            style: TextStyle(
                                color: AppColors.gray500, fontSize: 13)),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          ErrorBox(_error!),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            labelText: 'Admin Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Unlock Admin Panel'),
                        ),
                      ],
                    ),
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
