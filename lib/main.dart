import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/landing_screen.dart';
import 'screens/dashboard/dashboard_shell.dart';
import 'services/auth_service.dart';
import 'theme.dart';

void main() {
  // Uncaught async errors land in the zone handler instead of killing the app.
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    // Build-time errors show a readable screen instead of a grey box.
    ErrorWidget.builder = (details) => AppErrorScreen(
          title: 'কিছু একটা সমস্যা হয়েছে',
          message: kDebugMode ? details.exceptionAsString() : null,
        );
    runApp(const WorkerGigApp());
  }, (error, stack) {
    debugPrint('UNCAUGHT: $error\n$stack');
  });
}

class WorkerGigApp extends StatefulWidget {
  const WorkerGigApp({super.key});

  @override
  State<WorkerGigApp> createState() => _WorkerGigAppState();
}

class _WorkerGigAppState extends State<WorkerGigApp> {
  final AuthService auth = AuthService();
  final _navigatorKey = GlobalKey<NavigatorState>();
  Future<void>? _init;

  Future<void> _start() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
    await auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: FutureBuilder<void>(
          future: _init ??= _start(),
          builder: (context, snap) {
            if (snap.hasError) {
              return AppErrorScreen(
                title: 'সার্ভারে সংযোগ করা যাচ্ছে না',
                message: friendlyError(snap.error ?? 'unknown error'),
                retryLabel: 'আবার চেষ্টা করুন',
                onRetry: () => setState(() => _init = null),
              );
            }
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const AuthGate();
          },
        ),
      ),
    );
  }
}

/// Decides between Landing and Dashboard based on the Supabase session —
/// the same job ProtectedRoute does on the website.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (auth.user == null) return const LandingScreen();
    return const DashboardShell();
  }
}

/// Friendly full-screen error — shown for build errors and startup failures
/// so the app never dies silently.
class AppErrorScreen extends StatelessWidget {
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const AppErrorScreen({
    super.key,
    required this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.gray600),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.gray600)),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onRetry,
                  child: Text(retryLabel ?? 'Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

