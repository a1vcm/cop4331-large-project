import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand color tokens — kept in exact sync with `frontend/src/theme.js`'s
/// `C` export. If that file changes, update these hex values to match.
class AppColors {
  static const gold = Color(0xFFF2C417);
  static const goldDark = Color(0xFFBD9A36);
  static const goldLight = Color(0xFFF5D77A);
  static const goldPale = Color(0xFFFBEBBE);

  static const black = Color(0xFF1A1A1A);
  static const grayDark = Color(0xFF333333);
  static const grayMedium = Color(0xFF555555);
  static const grayLight = Color(0xFF888888);
  static const grayLighter = Color(0xFFBBBBBB);
  static const grayLightest = Color(0xFFEAEAEA);
  static const white = Color(0xFFFFFFFF);

  // --- Semantic aliases, mirroring the `T` object in theme.js ---
  static const primary = gold;
  static const onPrimary = black;
  static const text = black;
  static const textMuted = grayMedium;
  static const background = white;
  static const surface = grayLightest;
  static const border = grayLight;

  // Screen-chrome specific aliases used by AppScaffold/AppTopBar/etc.
  static const topBar = black;
  static const bottomBar = black;
  static const cardFill = grayLightest;
  static const fieldFill = Color(0x33888888); // grayLight @ 20% opacity
  static const accent = gold;
}

/// Spacing scale — matches `S` in theme.js exactly.
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 40.0;
}

/// Font weights — matches `fW` in theme.js exactly.
class AppFontWeights {
  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const bold = FontWeight.w700;
}

/// Typography.
///
/// theme.js defines three font stacks: `display` (Knockout), `heading`
/// (Gotham), and `body` (Helvetica Neue) — all licensed fonts with fallback
/// stacks. Flutter can't do CSS-style font-fallback-chains the same way,
/// and bundling Knockout/Gotham raises the same licensing question we
/// flagged earlier (worth raising with whoever owns the brand guide,
/// since the web app is shipping those font names in its CSS too).
///
/// For now every style below uses Montserrat via google_fonts as a
/// license-safe stand-in for both Gotham and Knockout. If your team gets
/// a confirmed license, swap `GoogleFonts.montserrat(...)` for
/// `GoogleFonts.knockout(...)` / a licensed Gotham asset — the rest of
/// the app won't need to change since everything reads from here.
class AppTextStyles {
  static TextStyle get display => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.bold,
        fontSize: 28,
        color: AppColors.text,
      );

  static TextStyle get heading => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.bold,
        fontSize: 20,
        color: AppColors.text,
      );

  static TextStyle get subheading => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.medium,
        fontSize: 15,
        color: AppColors.grayDark,
      );

  static TextStyle get body => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.regular,
        fontSize: 14,
        color: AppColors.grayDark,
      );

  static TextStyle get muted => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.regular,
        fontSize: 12,
        color: AppColors.textMuted,
      );

  static TextStyle get button => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.medium,
        fontSize: 14,
        color: AppColors.white,
      );
}

/// App-wide ThemeData, so MaterialApp components (buttons, inputs, etc.)
/// pick up brand colors automatically without repeating styles per screen.
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      textTheme: GoogleFonts.montserratTextTheme(),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.primary,
        secondary: AppColors.goldDark,
        surface: AppColors.surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.grayDark,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + 4),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.fieldFill,
        contentPadding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 2,
          horizontal: AppSpacing.md - 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        hintStyle: AppTextStyles.muted,
      ),
    );
  }
}
