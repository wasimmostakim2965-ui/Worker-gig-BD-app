import 'package:flutter/material.dart';

import '../theme.dart';

/// App logo — mirrors the website's Logo component (WG mark + wordmark).
class WGLogo extends StatelessWidget {
  final double size;
  final bool light;
  const WGLogo({super.key, this.size = 40, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary600, AppColors.primary800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          alignment: Alignment.center,
          child: Text(
            'WG',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: size * 0.42,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'WORKER GIG BD',
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: light ? Colors.white : AppColors.gray900,
              ),
            ),
            Text(
              'Earn Money Online',
              style: TextStyle(
                fontSize: size * 0.22,
                color: light ? AppColors.primary100 : AppColors.gray500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small colored status pill — matches the website's Badge variants.
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'active' || 'approved' || 'success' => (
          AppColors.success100,
          AppColors.success600
        ),
      'pending' || 'submitted' => (AppColors.primary100, AppColors.primary700),
      'rejected' || 'blocked' || 'error' => (
          AppColors.error100,
          AppColors.error600
        ),
      'paused' || 'suspended' || 'warning' => (
          const Color(0xFFFEF3C7),
          AppColors.warning600
        ),
      _ => (AppColors.gray100, AppColors.gray600),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class ErrorBox extends StatelessWidget {
  final String message;
  const ErrorBox(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error50,
        border: Border.all(color: AppColors.error100),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.error600, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const EmptyView(this.icon, this.title, {this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.gray500.withAlpha(120)),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gray600)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.gray500)),
            ],
          ],
        ),
      ),
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: error ? AppColors.error600 : AppColors.success600,
    behavior: SnackBarBehavior.floating,
  ));
}
