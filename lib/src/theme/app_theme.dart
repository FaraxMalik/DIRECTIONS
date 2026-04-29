import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens for the entire app.
///
/// Palette: deep crimson primary on a warm beige canvas with creamy surfaces,
/// inspired by classic editorial / library aesthetics.
class AppColors {
  AppColors._();

  // Primary crimson family
  static const Color crimson = Color(0xFFB20000);
  static const Color crimsonDark = Color(0xFF7A0000);
  static const Color crimsonDeep = Color(0xFF5A0000);
  static const Color crimsonSoft = Color(0xFFD64545);

  // Beige / cream canvas
  static const Color beige = Color(0xFFFFFEF0);
  static const Color beigeWarm = Color(0xFFF7EFDE);
  static const Color beigeDeep = Color(0xFFEFE3C7);
  static const Color cream = Color(0xFFFFF8E7);
  static const Color parchment = Color(0xFFF5EDD8);

  // Ink / text
  static const Color ink = Color(0xFF2A1A1A);
  static const Color inkSoft = Color(0xFF5C4A4A);
  static const Color inkMuted = Color(0xFF8A7575);

  // Accents
  static const Color gold = Color(0xFFC9A24A);
  static const Color success = Color(0xFF2E7D55);
  static const Color warning = Color(0xFFC97A1F);
  static const Color danger = Color(0xFFB23A3A);

  // Surfaces
  static const Color surface = Color(0xFFFFFDF6);
  static const Color surfaceAlt = Color(0xFFF7EFDE);
  static const Color border = Color(0x1A2A1A1A); // ink @ 10%

  // Useful gradients
  static const LinearGradient crimsonGradient = LinearGradient(
    colors: [crimson, crimsonDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient beigeGradient = LinearGradient(
    colors: [beige, beigeWarm],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppRadii {
  AppRadii._();
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double pill = 999;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.crimson,
      brightness: Brightness.light,
      primary: AppColors.crimson,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: AppColors.ink,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );

    final textTheme = _buildTextTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.beige,
      canvasColor: AppColors.beige,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.beige,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.crimson,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.crimson,
          side: const BorderSide(color: AppColors.crimson, width: 1.5),
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.crimson,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.10)),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: GoogleFonts.inter(color: AppColors.inkMuted),
        labelStyle: GoogleFonts.inter(
            color: AppColors.inkSoft, fontWeight: FontWeight.w500),
        floatingLabelStyle: GoogleFonts.inter(
            color: AppColors.crimson, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide:
              BorderSide(color: AppColors.crimson.withValues(alpha: 0.18)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide:
              BorderSide(color: AppColors.crimson.withValues(alpha: 0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide:
              const BorderSide(color: AppColors.crimson, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide:
              const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.crimson.withValues(alpha: 0.08),
        selectedColor: AppColors.crimson,
        labelStyle: GoogleFonts.inter(
            color: AppColors.crimsonDark, fontWeight: FontWeight.w600),
        secondaryLabelStyle:
            GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.crimson,
        linearTrackColor: AppColors.beigeDeep,
        circularTrackColor: AppColors.beigeDeep,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle:
            GoogleFonts.inter(color: AppColors.beige, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.beigeDeep,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.ink),
    );
  }

  static TextTheme _buildTextTheme(ColorScheme cs) {
    final display = GoogleFonts.playfairDisplayTextTheme();
    final body = GoogleFonts.interTextTheme();

    return TextTheme(
      displayLarge: display.displayLarge?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700, letterSpacing: -1),
      displayMedium: display.displayMedium?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700),
      displaySmall: display.displaySmall?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700),
      headlineLarge: display.headlineLarge?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700),
      headlineMedium: display.headlineMedium?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700),
      headlineSmall: display.headlineSmall?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w700),
      titleMedium: body.titleMedium?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w600),
      titleSmall: body.titleSmall?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge?.copyWith(color: AppColors.ink, height: 1.55),
      bodyMedium: body.bodyMedium?.copyWith(color: AppColors.ink, height: 1.5),
      bodySmall: body.bodySmall?.copyWith(color: AppColors.inkSoft),
      labelLarge: body.labelLarge?.copyWith(
          color: cs.onSurface, fontWeight: FontWeight.w600),
      labelMedium: body.labelMedium?.copyWith(color: AppColors.inkSoft),
      labelSmall: body.labelSmall?.copyWith(color: AppColors.inkSoft),
    );
  }
}
