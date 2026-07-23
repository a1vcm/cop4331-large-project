import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Raw palette — kept in exact sync with `frontend/src/theme.css`'s
/// `:root` block. If that file changes, update these hex values to match.
class AppPalette {
  // gold (light accent)
  static const goldDark = Color(0xFF896805);
  static const gold = Color(0xFFF2C417);
  static const goldLight = Color(0xFFF7D75A);

  // space-night (dark accent)
  static const blue = Color(0xFF2E6BE6);
  static const blueLight = Color(0xFF5B8DEF);
  static const spaceBlack = Color(0xFF0A0E1A);
  static const spaceSurface = Color(0xFF16203B);
  static const spaceBorder = Color(0xFF2A3350);
  static const spaceMuted = Color(0xFF9AA3B8);

  // neutrals
  static const black = Color(0xFF1A1A1A);
  static const gray900 = Color(0xFF333333);
  static const gray500 = Color(0xFF4c4c4c);
  static const gray300 = Color(0xFFBBBBBB);
  static const pageGray = Color(0xFFEDEFF1);
  static const white = Color(0xFFFFFFFF);

  // status
  static const error = Color(0xFFE57373);
  static const success = Color(0xFF3FA34D);
}

/// Manual light/dark switching, mirroring the web app's ThemeToggle.jsx +
/// localStorage persistence. A notifiable singleton (same pattern as
/// AuthState) that MaterialApp listens to.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'knightrate_theme';

  ThemeMode mode = ThemeMode.light;

  bool get isDark => mode == ThemeMode.dark;

  /// Await once at startup, alongside AuthState.loadFromDisk().
  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> toggle() async {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, isDark ? 'dark' : 'light');
  }
}

/// Semantic, theme-aware colors — the Flutter mirror of theme.css's
/// `--color-*` custom properties.
///
/// These take a BuildContext and read the ambient Theme's brightness, which
/// registers a dependency: any widget calling e.g. ThemeColors.bg(context)
/// automatically rebuilds the instant the skin flips. (An earlier revision
/// used context-free getters; const screens then skipped rebuilding and the
/// UI lagged one interaction behind the toggle.)
class ThemeColors {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext c) => _isDark(c) ? AppPalette.spaceBlack : AppPalette.pageGray;
  static Color surface(BuildContext c) => _isDark(c) ? AppPalette.spaceSurface : AppPalette.white;
  static Color text(BuildContext c) => _isDark(c) ? AppPalette.white : AppPalette.black;
  static Color textMuted(BuildContext c) => _isDark(c) ? AppPalette.spaceMuted : AppPalette.gray500;
  static Color border(BuildContext c) => _isDark(c) ? AppPalette.spaceBorder : AppPalette.gray300;

  static Color primary(BuildContext c) => _isDark(c) ? AppPalette.blue : AppPalette.gold;
  static Color primaryHover(BuildContext c) => _isDark(c) ? AppPalette.blueLight : AppPalette.goldDark;
  static Color onPrimary(BuildContext c) => _isDark(c) ? AppPalette.white : AppPalette.black;

  static Color emphasis(BuildContext c) => _isDark(c) ? AppPalette.blue : AppPalette.black;
  static Color emphasisHover(BuildContext c) => _isDark(c) ? AppPalette.blueLight : AppPalette.gray900;
  static Color onEmphasis(BuildContext c) => AppPalette.white;

  static Color error(BuildContext c) => AppPalette.error;
  static Color success(BuildContext c) => AppPalette.success;
}

/// Fixed brand color tokens. Values refreshed to match theme.css's raw
/// palette; names preserved so every existing screen keeps compiling.
/// These do NOT change with dark mode — prefer ThemeColors for anything
/// that should. Chrome colors (topBar/bottomBar) are intentionally fixed:
/// the web app's TopBar.css also pins its background to var(--black) in
/// both skins.
class AppColors {
  static const gold = AppPalette.gold;
  static const goldDark = AppPalette.goldDark;
  static const goldLight = AppPalette.goldLight;
  static const goldPale = Color(0xFFFBEBBE);

  static const black = AppPalette.black;
  static const grayDark = AppPalette.gray900;
  static const grayMedium = Color(0xFF555555);
  static const grayLight = AppPalette.gray500;
  static const grayLighter = AppPalette.gray300;
  static const grayLightest = AppPalette.pageGray;
  static const white = AppPalette.white;

  static const primary = gold;
  static const onPrimary = black;
  static const text = black;
  static const textMuted = grayMedium;
  static const background = white;
  static const surface = grayLightest;
  static const border = grayLight;

  static const topBar = black;
  static const bottomBar = black;
  static const cardFill = grayLightest;
  static const fieldFill = Color(0x33888888); // grayLight @ 20% opacity
  static const accent = gold;
}

/// Review-card container styling. Matches ReviewCard.css's own base rule
/// (`--color-bg`/10px radius/16-18px padding/blur-4 shadow) — always
/// theme-aware, unlike the web version where CourseDetailPage.css and
/// BookmarksPage.css both hardcode a white background via a
/// `.review-list > *` / `.bookmarks-list > *` child-combinator rule that
/// ignores dark mode. Mobile intentionally diverges here rather than
/// reproducing that bug.
class AppCardStyle {
  static const baseRadius = 10.0;
  static const baseHPad = 18.0;
  static const baseVPad = 16.0;
  static List<BoxShadow> baseShadow(BuildContext context) => [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1)),
      ];
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

/// Typography. Montserrat via google_fonts as the license-safe stand-in
/// for Gotham/Knockout, same as the web app. Styles read ThemeColors so
/// text flips correctly in dark mode wherever these are used.
class AppTextStyles {
  static bool get _dark => ThemeController.instance.isDark;
  static Color get _text => _dark ? AppPalette.white : AppPalette.black;
  static Color get _muted => _dark ? AppPalette.spaceMuted : AppPalette.gray500;

  static TextStyle get display => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.bold,
        fontSize: 28,
        color: _text,
      );

  static TextStyle get heading => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.bold,
        fontSize: 20,
        color: _text,
      );

  static TextStyle get subheading => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.medium,
        fontSize: 15,
        color: _text,
      );

  // Body/muted text mirrors the web's "Helvetica Neue", Arial, sans-serif
  // stack — only headings/tabs/buttons use Montserrat there. Leaving
  // fontFamily unset falls back to the platform default (San Francisco on
  // iOS), which is the closest native equivalent to Helvetica Neue and
  // matches what the rest of the app's chrome (nav bar, tab bar) already
  // renders in, instead of forcing Montserrat everywhere.
  static TextStyle get body => TextStyle(
        fontWeight: AppFontWeights.regular,
        fontSize: 14,
        color: _text,
      );

  static TextStyle get muted => TextStyle(
        fontWeight: AppFontWeights.regular,
        fontSize: 12,
        color: _muted,
      );

  static TextStyle get button => GoogleFonts.montserrat(
        fontWeight: AppFontWeights.medium,
        fontSize: 14,
        color: AppPalette.white,
      );
}

/// Light + dark ThemeData mirroring theme.css's two skins. main.dart wires
/// these to MaterialApp.theme / darkTheme with ThemeController driving
/// themeMode.
class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppPalette.pageGray,
        surface: AppPalette.white,
        text: AppPalette.black,
        muted: AppPalette.gray500,
        primary: AppPalette.gold,
        onPrimary: AppPalette.black,
        emphasis: AppPalette.black,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppPalette.spaceBlack,
        surface: AppPalette.spaceSurface,
        text: AppPalette.white,
        muted: AppPalette.spaceMuted,
        primary: AppPalette.blue,
        onPrimary: AppPalette.white,
        emphasis: AppPalette.blue,
      );

  /// Kept for compatibility with any code still reading AppTheme.theme.
  static ThemeData get theme => light;

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color text,
    required Color muted,
    required Color primary,
    required Color onPrimary,
    required Color emphasis,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      // System font (San Francisco on iOS) as the default, matching the
      // web's Helvetica Neue body-text stack — Montserrat is applied
      // explicitly via AppTextStyles.display/heading/subheading/button
      // only, mirroring exactly which elements the web sets Montserrat on.
      textTheme: brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: primary,
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emphasis,
          foregroundColor: AppPalette.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm + 4, horizontal: AppSpacing.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.dark
            ? AppPalette.spaceBorder.withValues(alpha: 0.5)
            : AppColors.fieldFill,
        contentPadding: EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 2,
          horizontal: AppSpacing.md - 4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide.none,
        ),
        hintStyle: GoogleFonts.montserrat(
          fontWeight: AppFontWeights.regular,
          fontSize: 12,
          color: muted,
        ),
      ),
    );
  }
}
