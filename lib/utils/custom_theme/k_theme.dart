import 'package:flutter/material.dart';
import 'k_palette.dart';
import 'text_theme.dart';

/// The app's two themes.
///
/// Every component theme below exists so screens don't have to style that
/// component themselves. If you find yourself writing a colour literal in
/// a screen, the component theme here is probably missing something — fix
/// it here rather than at the call site.
///
/// Replaces appbar_theme.dart and bottomnav_theme.dart, which can be
/// deleted. The old light app bar was unusable: lightGreenAccent icons on
/// a lightGreenAccent background.
class KTheme {
  KTheme._();

  static final ColorScheme _lightScheme = const ColorScheme.light().copyWith(
    primary: KPalette.brand,
    onPrimary: Colors.white,
    primaryContainer: KPalette.brandContainer,
    onPrimaryContainer: const Color(0xFF00603F),
    secondary: KPalette.brandText,
    onSecondary: Colors.white,
    surface: KPalette.lightSurface,
    onSurface: KPalette.lightTextPrimary,
    surfaceContainerLowest: KPalette.lightSurface,
    surfaceContainerLow: KPalette.lightBackground,
    surfaceContainer: KPalette.lightSurfaceVariant,
    onSurfaceVariant: KPalette.lightTextSecondary,
    outline: KPalette.lightBorder,
    outlineVariant: const Color(0xFFEDF2EF),
    error: const Color(0xFF9B2220),
    onError: Colors.white,
    errorContainer: const Color(0xFFFBE9E9),
    onErrorContainer: const Color(0xFF6B1614),
  );

  static final ColorScheme _darkScheme = const ColorScheme.dark().copyWith(
    primary: KPalette.brand,
    onPrimary: Colors.white,
    primaryContainer: KPalette.brandContainerDark,
    onPrimaryContainer: KPalette.brandTextDark,
    secondary: KPalette.brandTextDark,
    onSecondary: Colors.black,
    surface: KPalette.darkSurface,
    onSurface: KPalette.darkTextPrimary,
    surfaceContainerLowest: KPalette.darkBackground,
    surfaceContainerLow: KPalette.darkSurface,
    surfaceContainer: KPalette.darkSurfaceVariant,
    onSurfaceVariant: KPalette.darkTextSecondary,
    outline: KPalette.darkBorder,
    outlineVariant: const Color(0xFF242424),
    error: const Color(0xFFF09595),
    onError: Colors.black,
    errorContainer: const Color(0xFF3A1514),
    onErrorContainer: const Color(0xFFF7C1C1),
  );

  /// Light theme. Option C — faint green-tinted page, white cards.
  static final ThemeData light = buildKTheme(
    brightness: Brightness.light,
    scheme: _lightScheme,
    background: KPalette.lightBackground,
    border: KPalette.lightBorder,
    muted: KPalette.lightTextMuted,
    status: KStatusColors.light,
  );

  /// Dark theme. Matches the near-black surfaces already in use.
  static final ThemeData dark = buildKTheme(
    brightness: Brightness.dark,
    scheme: _darkScheme,
    background: KPalette.darkBackground,
    border: KPalette.darkBorder,
    muted: KPalette.darkTextMuted,
    status: KStatusColors.dark,
  );
}

/// Builds the component themes. Called once per mode.
///
/// Attach with:  KTheme.light  /  KTheme.dark   (already wired above)
ThemeData buildKTheme({
  required Brightness brightness,
  required ColorScheme scheme,
  required Color background,
  required Color border,
  required Color muted,
  required KStatusColors status,
}) {
  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Poppins',
    dividerColor: border,
    extensions: [status],

    textTheme: KAppTextTheme.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    ),

    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: isDark ? KPalette.darkBackground : scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      // Icons must contrast with the bar, not match it. The old light
      // theme set both to lightGreenAccent, which made them invisible.
      iconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      actionsIconTheme: IconThemeData(color: scheme.onSurface, size: 24),
      titleTextStyle: KAppTextTheme.textTheme.titleLarge?.copyWith(
        color: scheme.onSurface,
      ),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? KPalette.darkSurface : scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: muted,
      selectedLabelStyle: KAppTextTheme.textTheme.labelSmall,
      unselectedLabelStyle: KAppTextTheme.textTheme.labelSmall,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? KPalette.darkSurfaceVariant : scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: muted),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.error),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.primary.withOpacity(0.4),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: KAppTextTheme.textTheme.labelLarge,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: border),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: KAppTextTheme.textTheme.labelLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        // Text green, not fill green — contrast on a light surface.
        foregroundColor: isDark ? KPalette.brandTextDark : KPalette.brandText,
        textStyle: KAppTextTheme.textTheme.labelLarge,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 2,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: isDark ? KPalette.darkSurfaceVariant : background,
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: border),
      labelStyle: KAppTextTheme.textTheme.labelMedium,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: KAppTextTheme.textTheme.titleMedium?.copyWith(
        color: scheme.onSurface,
      ),
      contentTextStyle: KAppTextTheme.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),

    // Fixes the invisible calendar. Screens previously wrapped pickers in
    // `Theme(data: ... ColorScheme.light(primary: X))`, which replaced the
    // whole scheme with light-mode defaults and rendered black on black.
    // With this in place, delete those local builder overrides.
    datePickerTheme: DatePickerThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: scheme.primary,
      headerForegroundColor: scheme.onPrimary,
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : Colors.transparent,
      ),
      todayForegroundColor: WidgetStateProperty.all(scheme.primary),
      todayBorder: BorderSide(color: scheme.primary),
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: scheme.surface,
      dialHandColor: scheme.primary,
      hourMinuteColor: isDark ? KPalette.darkSurfaceVariant : background,
      hourMinuteTextColor: scheme.onSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? KPalette.darkSurfaceVariant
          : const Color(0xFF10201A),
      contentTextStyle: KAppTextTheme.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    listTileTheme: ListTileThemeData(
      textColor: scheme.onSurface,
      iconColor: scheme.onSurfaceVariant,
      subtitleTextStyle: KAppTextTheme.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    ),

    dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),

    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: muted,
      indicatorColor: scheme.primary,
      dividerColor: Colors.transparent,
      labelStyle: KAppTextTheme.textTheme.titleSmall,
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? scheme.primary : muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? scheme.primaryContainer : border,
      ),
    ),
  );
}
