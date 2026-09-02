import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The one and only URL the app renders. Everything the website does —
/// login, dashboard, jobs, deposits, admin — works identically here because
/// the app IS the website, rendered in a full-screen WebView.
const String kHomeUrl = 'https://www.workergigbd.site';

/// Hosts that must load INSIDE the WebView (the site itself plus its own
/// backend endpoints such as Supabase auth callbacks).
bool _isInternalUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  return host == 'workergigbd.site' ||
      host.endsWith('.workergigbd.site') ||
      host.endsWith('.supabase.co');
}

/// Everything else (WhatsApp, bKash links, tel:, mailto:, Google OAuth,
/// Facebook, ...) opens in the device's external browser/app.
Future<void> _openExternally(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // No app can handle this link — ignore quietly.
  }
}

void main() {
  runApp(const WorkerGigApp());
}

class WorkerGigApp extends StatelessWidget {
  const WorkerGigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Worker Gig BD',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0E9F6E)),
        useMaterial3: true,
      ),
      home: const WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageStarted: (_) => setState(() {
            _hasError = false;
            _progress = 0;
          }),
          onPageFinished: (_) => setState(() => _progress = 100),
          onWebResourceError: (error) {
            // Only surface errors for the main page; failed images/scripts
            // shouldn't replace the whole screen.
            if (error.isForMainFrame ?? false) {
              setState(() {
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;

            // Keep the site and its backend inside the app.
            if (_isInternalUrl(uri)) return NavigationDecision.navigate;

            // Google sign-in must happen in a real browser — Google blocks
            // OAuth inside embedded WebViews by policy.
            _openExternally(request.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(kHomeUrl));
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _progress = 0;
    });
    _controller.loadRequest(Uri.parse(kHomeUrl));
  }

  Future<bool> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // stay in the app
    }
    return true; // no history — let the system close the app
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _handleBack() && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (_progress < 100 && !_hasError)
                LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                ),
              Expanded(
                child: _hasError
                    ? _OfflineView(message: _errorMessage, onRetry: _reload)
                    : WebViewWidget(controller: _controller),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _OfflineView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'ইন্টারনেট সংযোগ নেই',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'আপনার ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('আবার চেষ্টা করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
