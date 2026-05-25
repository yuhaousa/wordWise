import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ── Brand colors ─────────────────────────────────────────
  static const Color primary       = Color(0xFF4F46E5); // indigo
  static const Color primaryLight  = Color(0xFF818CF8);
  static const Color secondary     = Color(0xFF10B981); // emerald
  static const Color accent        = Color(0xFFF59E0B); // amber
  static const Color error         = Color(0xFFEF4444);
  static const Color background    = Color(0xFFF9FAFB);
  static const Color surface       = Colors.white;
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // CEFR level colors
  static const Map<String, Color> cefrColors = {
    'A1': Color(0xFF86EFAC), // green-300
    'A2': Color(0xFF6EE7B7), // emerald-300
    'B1': Color(0xFF93C5FD), // blue-300
    'B2': Color(0xFF818CF8), // indigo-300
    'C1': Color(0xFFC4B5FD), // violet-300
    'C2': Color(0xFFF9A8D4), // pink-300
  };

  static Color cefrColor(String level) => cefrColors[level] ?? Colors.grey.shade300;

  // ── Light theme ──────────────────────────────────────────
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );
    return base.copyWith(
      textTheme: GoogleFonts.nunitoTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withOpacity(0.1),
        labelStyle: GoogleFonts.nunito(color: primary, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withOpacity(0.14),
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.nunito(
              color: primary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return GoogleFonts.nunito(
            color: textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 6,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w600),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
