import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../models.dart';

/// Auth + profile state, mirroring the website's AuthContext:
/// - Google OAuth (PKCE) with deep-link callback
/// - Email/password (used by the admin gate)
/// - Profile row auto-heal (insert minimal profile if the trigger missed)
class AuthService extends ChangeNotifier {
  SupabaseClient get client => Supabase.instance.client;

  User? user;
  Profile? profile;
  bool loading = true;

  StreamSubscription<AuthState>? _sub;

  void init() {
    _sub = client.auth.onAuthStateChange.listen((state) async {
      user = state.session?.user;
      if (user != null) {
        await _loadProfile(user!.id);
      } else {
        profile = null;
      }
      loading = false;
      notifyListeners();
    });
    user = client.auth.currentUser;
    if (user != null) {
      _loadProfile(user!.id).then((_) {
        loading = false;
        notifyListeners();
      });
    } else {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile(String uid, [int retry = 0]) async {
    try {
      final data = await client
          .from('profiles')
          .select()
          .eq('id', uid)
          .maybeSingle();
      if (data != null) {
        profile = Profile.fromJson(data);
        notifyListeners();
        return;
      }
      // Self-heal: no profile row yet — insert a minimal one (same as web).
      if (retry == 0) {
        final email = user?.email ?? '';
        final username = email.contains('@') ? email.split('@').first : 'user';
        try {
          await client.from('profiles').insert({
            'id': uid,
            'username': username,
            'referral_code':
                'WG${uid.replaceAll('-', '').substring(0, 8).toUpperCase()}',
            'status': 'active',
          });
        } catch (_) {/* trigger may have created it concurrently */}
        return _loadProfile(uid, 1);
      }
      if (retry < 3) {
        await Future.delayed(const Duration(seconds: 1));
        return _loadProfile(uid, retry + 1);
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  Future<void> refreshProfile() async {
    final u = client.auth.currentUser;
    if (u != null) await _loadProfile(u.id);
  }

  /// Google sign-in/sign-up (same OAuth flow as the website).
  Future<String?> signInWithGoogle({String? referralCode}) async {
    try {
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: AppConfig.oauthRedirect,
        queryParams:
            referralCode != null && referralCode.isNotEmpty
                ? {'ref': referralCode}
                : null,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  /// Email/password — used by the admin gate (same as the website).
  Future<String?> signInWithPassword(String email, String password) async {
    try {
      await client.auth
          .signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return '$e';
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
    profile = null;
    user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
