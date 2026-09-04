import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme.dart';

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

  Future<void> init() async {
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
    // Deferred so notifyListeners() never fires during the first build.
    await Future(() async {
      user = client.auth.currentUser;
      if (user != null) {
        await _loadProfile(user!.id);
      }
      loading = false;
      notifyListeners();
    });
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

  /// Google sign-in/sign-up using the native google_sign_in plugin.
  /// Tapping the button opens Google's account picker (list of the Gmail
  /// accounts on the phone) — no password typing, no browser, no WebView.
  final _google = GoogleSignIn(scopes: ['openid', 'email', 'profile']);

  Future<String?> signInWithGoogle({String? referralCode}) async {
    try {
      final account = await _google.signIn();
      if (account == null) return 'Sign-in cancelled.';
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) return 'Google did not return an ID token.';
      await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return friendlyError(e);
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
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
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
