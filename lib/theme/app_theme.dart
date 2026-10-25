import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  // Brand & Accent - Light
  static const primary = Color(0xFF1E88E5);
  static const secondary = Color(0xFFDCEAFE);

  // Brand & Accent - Dark
  static const primaryDark = Color(0xFFA2C9FF);
  static const secondaryDark = Color(0xFF253243);

  // Surfaces & Backgrounds - Light
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceSubtleLight = Color(0xFFF3F4F8);
  static const surfaceElevatedLight = Color(0xFFFFFFFF);

  // Surfaces & Backgrounds - Dark
  static const backgroundDark = Color(0xFF141820);
  static const surfaceDark = Color(0xFF171C21);
  static const surfaceSubtleDark = Color(0xFF202733);
  static const surfaceElevatedDark = Color(0xFF1E232B);

  // Neutrals & Typography - Light
  static const textPrimaryLight = Color(0xFF1A1C1E);
  static const textSecondaryLight = Color(0xFF5E6368);
  static const borderSubtleLight = Color(0xFFE2E5EB);
  static const borderHairlineLight = Color(0xFFEBF0F7);
  static const dividerLight = Color(0xFFF0F2F6);
  static const iconMutedLight = Color(0xFF74777F);

  // Neutrals & Typography - Dark
  static const textPrimaryDark = Color(0xFFEDF1F8);
  static const textSecondaryDark = Color(0xFFA0A7B4);
  static const borderSubtleDark = Color(0xFF404752);
  static const borderHairlineDark = Color(0xFF2C3136);
  static const dividerDark = Color(0xFF2C3136);
  static const iconMutedDark = Color(0xFF8E9199);

  // Status
  static const error = Color(0xFFBA1A1A);
  static const errorDark = Color(0xFFFFB4AB);

  // Dynamic color resolution based on brightness
  static Color primaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? primaryDark : primary;

  static Color secondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? secondaryDark
      : secondary;

  static Color backgroundOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? backgroundDark
      : backgroundLight;

  static Color surfaceSubtleOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? surfaceSubtleDark
      : surfaceSubtleLight;

  static Color surfaceElevatedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? surfaceElevatedDark
      : surfaceElevatedLight;

  static Color textPrimaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textPrimaryDark
      : textPrimaryLight;

  static Color textSecondaryOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? textSecondaryDark
      : textSecondaryLight;

  static Color iconMutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? iconMutedDark
      : iconMutedLight;

  static Color borderSubtleOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? borderSubtleDark
      : borderSubtleLight;

  static Color borderHairlineOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? borderHairlineDark
      : borderHairlineLight;

  static Color dividerOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? dividerDark
      : dividerLight;
}

abstract final class AppTheme {
  static TextTheme _buildTextTheme({required bool dark}) {
    final textColor = dark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final baseTextTheme = dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return GoogleFonts.plusJakartaSansTextTheme(baseTextTheme).copyWith(
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 28 / 22,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 22 / 16,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 22 / 15,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: textColor,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color: textColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        color: textColor,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 14 / 11,
        color: secondaryTextColor,
      ),
    );
  }

  static ThemeData light() {
    final textTheme = _buildTextTheme(dark: false);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: textTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.secondary,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimaryLight,
        secondaryContainer: AppColors.secondary,
        onSecondaryContainer: AppColors.textPrimaryLight,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        surfaceContainerLow: AppColors.surfaceSubtleLight,
        surfaceContainer: AppColors.surfaceSubtleLight,
        surfaceContainerHigh: AppColors.surfaceSubtleLight,
        outline: AppColors.borderSubtleLight,
        outlineVariant: AppColors.borderHairlineLight,
        error: AppColors.error,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        toolbarHeight: 56,
        centerTitle: true,
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryLight,
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: AppColors.textPrimaryLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtleLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryLight,
        ),
        prefixIconColor: AppColors.textSecondaryLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceSubtleLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: AppColors.borderHairlineLight,
            width: 1,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surfaceElevatedLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.secondary,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24, color: AppColors.primary);
          }
          return const IconThemeData(size: 24, color: AppColors.iconMutedLight);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.iconMutedLight,
          );
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevatedLight,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final textTheme = _buildTextTheme(dark: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: textTheme,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primaryDark,
        onPrimary: Color(0xFF001C38),
        primaryContainer: Color(0xFF004881),
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondaryDark,
        onSecondary: AppColors.textPrimaryDark,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.textPrimaryDark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerLow: AppColors.surfaceSubtleDark,
        surfaceContainer: AppColors.surfaceSubtleDark,
        surfaceContainerHigh: AppColors.surfaceSubtleDark,
        outline: AppColors.borderSubtleDark,
        outlineVariant: AppColors.borderHairlineDark,
        error: AppColors.errorDark,
        onError: Color(0xFF600008),
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: AppBarTheme(
        toolbarHeight: 56,
        centerTitle: true,
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(
          size: 24,
          color: AppColors.textPrimaryDark,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceSubtleDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
        ),
        prefixIconColor: AppColors.textSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primaryDark,
            width: 1.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceSubtleDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderHairlineDark, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryDark,
        foregroundColor: AppColors.primaryDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: AppColors.surfaceElevatedDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.secondaryDark,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 24, color: AppColors.primaryDark);
          }
          return const IconThemeData(size: 24, color: AppColors.iconMutedDark);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryDark,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.iconMutedDark,
          );
        }),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevatedDark,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: const Color(0xFF001C38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primaryDark, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
