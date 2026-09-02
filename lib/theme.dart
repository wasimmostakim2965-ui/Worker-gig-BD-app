import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors mirrored 1:1 from the website's tailwind.config.js so the app
/// looks identical to workergigbd.site.
class AppColors {
  static const primary50 = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary600 = Color(0xFF2563EB);
  static const primary700 = Color(0xFF1D4ED8);
  static const primary800 = Color(0xFF1E40AF);
  static const primary950 = Color(0xFF172554);

  static const gray50 = Color(0xFFF9FAFB);
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray900 = Color(0xFF111827);

  static const accent500 = Color(0xFFF59E0B);

  static const success50 = Color(0xFFF0FDF4);
  static const success100 = Color(0xFFDCFCE7);
  static const success600 = Color(0xFF16A34A);

  static const warning50 = Color(0xFFFFF7ED);
  static const warning600 = Color(0xFFEA580C);

  static const error50 = Color(0xFFFEF2F2);
  static const error100 = Color(0xFFFEE2E2);
  static const error600 = Color(0xFFDC2626);

  /// The green used on the web dashboard for earnings / TOP JOB badges.
  static const earnGreen = Color(0xFF0E9F6E);
}

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true);
  final body = GoogleFonts.interTextTheme(base.textTheme);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.gray50,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary600,
      primary: AppColors.primary600,
    ),
    textTheme: body.copyWith(
      headlineSmall: GoogleFonts.plusJakartaSans(
        textStyle: body.headlineSmall,
        fontWeight: FontWeight.w800,
        color: AppColors.gray900,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: body.titleLarge,
        fontWeight: FontWeight.w700,
        color: AppColors.gray900,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        textStyle: body.titleMedium,
        fontWeight: FontWeight.w600,
        color: AppColors.gray900,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.gray900,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.gray900,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.gray200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary600, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    ),
  );
}

/// Format money exactly like the website: `$ 0.000`
String fmtMoney(num? v) => '\$ ${(v ?? 0).toDouble().toStringAsFixed(3)}';
