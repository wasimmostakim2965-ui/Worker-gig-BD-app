import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../config.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';

/// Google sign-in happens fully INSIDE the app: this WebView opens the
/// Supabase Google OAuth page, the user picks their Gmail account here, and
/// the redirect back to com.workergigbd.app://login-callback is intercepted
/// and exchanged for a session — the external browser is never opened.
class OAuthWebViewScreen extends StatefulWidget {
  final String? referralCode;
  const OAuthWebViewScreen({super.key, this.referralCode});

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  WebViewController? _controller;
  bool _loading = true;
  bool _finishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final auth = context.read<AuthService>();
    try {
      final url =
          await auth.getGoogleSignInUrl(referralCode: widget.referralCode);
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (req) {
              if (req.url.startsWith(AppConfig.oauthRedirect)) {
                _finish(Uri.parse(req.url));
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
          ),
        )
        ..loadRequest(url);
      if (mounted) setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not start Google sign-in. Please try again.';
          _loading = false;
        });
      }
    }
  }

  Future<void> _finish(Uri uri) async {
    if (_finishing) return;
    _finishing = true;
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final error = await auth.completeOAuthSignIn(uri);
    if (!mounted) return;
    if (error == null) {
      Navigator.pop(context, true); // success — AuthGate will route us
    } else {
      setState(() {
        _error = error;
        _loading = false;
      });
      _finishing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in with Google'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_loading)
            const ColoredBox(
              color: Colors.white,
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            ColoredBox(
              color: Colors.white,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(color: AppColors.danger600)),
                      const SizedBox(height: 12),
                      FilledButton(
                          onPressed: () {
                            setState(() {
                              _error = null;
                              _loading = true;
                            });
                            _start();
                          },
                          child: const Text('Try Again')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
