// Regression tests that run the REAL app code against the REAL backend
// (anon key, RLS applies) to prove no screen crashes and model parsing
// survives hostile JSON.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:workergigbd/models.dart';
import 'package:workergigbd/services/auth_service.dart';
import 'package:workergigbd/theme.dart';
import 'package:workergigbd/screens/dashboard/dashboard_shell.dart';
import 'package:workergigbd/screens/dashboard/home_screen.dart';
import 'package:workergigbd/screens/dashboard/my_tasks_screen.dart';
import 'package:workergigbd/screens/dashboard/my_jobs_screen.dart';
import 'package:workergigbd/screens/dashboard/notifications_screen.dart';
import 'package:workergigbd/screens/dashboard/profile_screen.dart';
import 'package:workergigbd/screens/dashboard/deposit_screen.dart';
import 'package:workergigbd/screens/dashboard/deposit_history_screen.dart';
import 'package:workergigbd/screens/dashboard/withdraw_screen.dart';
import 'package:workergigbd/screens/dashboard/verify_screen.dart';
import 'package:workergigbd/screens/dashboard/ticket_screen.dart';
import 'package:workergigbd/screens/dashboard/premium_screen.dart';
import 'package:workergigbd/screens/dashboard/share_earn_screen.dart';
import 'package:workergigbd/screens/dashboard/advertisement_screen.dart';
import 'package:workergigbd/screens/dashboard/post_job_screen.dart';
import 'package:workergigbd/screens/dashboard/job_detail_screen.dart';
import 'package:workergigbd/screens/admin/admin_tasks_screen.dart';
import 'package:workergigbd/screens/landing_screen.dart';
import 'package:workergigbd/screens/auth/login_screen.dart';
import 'package:workergigbd/screens/auth/signup_screen.dart';

const _url = 'https://tsokfguhydwausvuaaiw.supabase.co';
const _anon = 'sb_publishable_hfgUFRLu1UrBd10ulCUgsA_po8qwPjw';

class _TestAuth extends AuthService {
  _TestAuth({Profile? p}) {
    profile = p;
    loading = false;
    if (p != null) {
      user = User(
        id: p.id,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2024-01-01T00:00:00Z',
      );
    }
  }
}

final _fakeProfile = Profile(
  id: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
  username: 'tester',
  fullName: 'Test User',
  earningBalance: 12.5,
  status: 'active',
);

Widget _wrap(Widget child, {Profile? p}) {
  return ChangeNotifierProvider<AuthService>.value(
    value: _TestAuth(p: p),
    child: MaterialApp(
      theme: buildAppTheme(),
      home: child,
    ),
  );
}

Future<void> _pumpAndSettleLoose(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

class _MemAsyncStorage extends GotrueAsyncStorage {
  final _m = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => _m[key];
  @override
  Future<void> removeItem({required String key}) async => _m.remove(key);
  @override
  Future<void> setItem({required String key, required String value}) async =>
      _m[key] = value;
}

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anon,
      authOptions: FlutterAuthClientOptions(
        localStorage: const EmptyLocalStorage(),
        pkceAsyncStorage: _MemAsyncStorage(),
        autoRefreshToken: false,
        detectSessionInUri: false,
      ),
    );
  });

  group('models survive hostile JSON', () {
    test('int columns arriving as double or string do not throw', () {
      final p = Profile.fromJson({
        'id': 'x',
        'tasks_completed': 3.9,
        'jobs_posted': '7',
        'earning_balance': '12.50',
        'total_earned': null,
      });
      expect(p.tasksCompleted, 3);
      expect(p.jobsPosted, 7);
      expect(p.earningBalance, 12.5);

      final c = Category.fromJson({'id': 'c', 'display_order': 2.0});
      expect(c.displayOrder, 2);

      final j = Job.fromJson({
        'id': 'j1',
        'screenshot_count': '2',
        'total_slots': 5.0,
        'filled_slots': null,
        'reward_per_worker': '0.010',
      });
      expect(j.screenshotCount, 2);
      expect(j.totalSlots, 5);
      expect(j.filledSlots, 0);
      expect(j.rewardPerWorker, 0.01);
    });

    test('missing/null ids do not throw (embedded selects)', () {
      final t = TaskItem.fromJson({
        'worker_id': null,
        'jobs': {'title': 'T', 'reward_per_worker': 1}, // no id
      });
      expect(t.id, '');
      expect(t.workerId, '');
      expect(t.job, isNotNull);

      expect(DepositRequest.fromJson({}).id, '');
      expect(WithdrawalRequest.fromJson({}).id, '');
      expect(AppNotification.fromJson({}).id, '');
    });

    test('helpers never throw', () {
      expect(shortId(''), '');
      expect(shortId('ab'), 'ab');
      expect(shortId('1234567890'), '12345678…');
      expect(fmt2('abc'), '0.00');
      expect(fmt2(5), '5.00');
      expect(fmt2(null), '0.00');
    });
  });

  group('screens render without crashing (logged out)', () {
    final cases = <String, Widget Function()>{
      'LandingScreen': () => const LandingScreen(),
      'LoginScreen': () => const LoginScreen(),
      'SignupScreen': () => const SignupScreen(),
    };
    for (final e in cases.entries) {
      testWidgets(e.key, (tester) async {
        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_wrap(e.value()));
        await _pumpAndSettleLoose(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('screens render without crashing (logged in, real backend)', () {
    final cases = <String, Widget Function()>{
      'DashboardShell': () => const DashboardShell(),
      'HomeScreen': () => const HomeScreen(),
      'MyTasksScreen': () => const MyTasksScreen(),
      'MyJobsScreen': () => const MyJobsScreen(),
      'NotificationsScreen': () => const NotificationsScreen(),
      'ProfileScreen': () => const ProfileScreen(),
      'DepositScreen': () => const DepositScreen(),
      'DepositHistoryScreen': () => const DepositHistoryScreen(),
      'WithdrawScreen': () => const WithdrawScreen(),
      'VerifyScreen': () => const VerifyScreen(),
      'TicketScreen': () => const TicketScreen(),
      'PremiumScreen': () => const PremiumScreen(),
      'ShareEarnScreen': () => const ShareEarnScreen(),
      'AdvertisementScreen': () => const AdvertisementScreen(),
      'PostJobScreen': () => const PostJobScreen(),
      'AdminTasksScreen': () => const AdminTasksScreen(),
      'JobDetailScreen': () => JobDetailScreen(
            job: Job(
              id: 'job-1',
              userId: 'someone',
              title: 'Test Job',
              url: 'not a url at all %%',
              screenshotCount: 2,
              totalSlots: 10,
              rewardPerWorker: 0.5,
            ),
          ),
      'JobSubmissionsScreen': () => JobSubmissionsScreen(
            job: Job(
              id: 'job-1',
              userId: 'someone',
              title: 'Test Job',
              screenshotCount: 1,
              totalSlots: 5,
            ),
          ),
    };
    for (final e in cases.entries) {
      testWidgets(e.key, (tester) async {
        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_wrap(e.value(), p: _fakeProfile));
        await _pumpAndSettleLoose(tester);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
