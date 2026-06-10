import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bap_pulse/core/theme/colors.dart';

ThemeData buildAppTheme() {
  const colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    secondary: AppColors.primaryDeep,
    onSecondary: AppColors.onPrimary,
    tertiary: AppColors.primarySoft,
    onTertiary: AppColors.onPrimary,
    error: AppColors.accentRed,
    onError: Colors.white,
    surface: AppColors.bgScaffold,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.bgCardElevated,
    onSurfaceVariant: AppColors.textMuted,
    outline: AppColors.outline,
    shadow: Colors.black,
    inverseSurface: AppColors.textPrimary,
    onInverseSurface: AppColors.bgScaffold,
    inversePrimary: Color(0xFF0A2A1B),
    scrim: Colors.black,
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgScaffold,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary),
    cardTheme: CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.bgScaffold,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgCard,
      hintStyle: GoogleFonts.inter(color: AppColors.textFaint, fontSize: 15),
      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
      prefixIconColor: AppColors.textMuted,
      suffixIconColor: AppColors.textMuted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: _inputBorder(AppColors.outline),
      enabledBorder: _inputBorder(AppColors.outline),
      focusedBorder: _inputBorder(AppColors.primary, width: 1.5),
      errorBorder: _inputBorder(AppColors.accentRed),
      focusedErrorBorder: _inputBorder(AppColors.accentRed, width: 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        textStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        elevation: 0,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
        disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.7),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.outline),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF203229),
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
    ),
    dividerColor: AppColors.divider,
  );

  return base;
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
