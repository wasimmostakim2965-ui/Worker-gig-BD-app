import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'screens/landing_screen.dart';
import 'screens/dashboard/dashboard_shell.dart';
import 'services/auth_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
  );
  runApp(const WorkerGigApp());
}

class WorkerGigApp extends StatefulWidget {
  const WorkerGigApp({super.key});

  @override
  State<WorkerGigApp> createState() => _WorkerGigAppState();
}

class _WorkerGigAppState extends State<WorkerGigApp> {
  late final AuthService auth = AuthService()..init();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: auth,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
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
