import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surfaceVariant = Color(0xFF1C2128);
  static const border = Color(0xFF30363D);
  static const borderLight = Color(0xFF21262D);
  static const accent = Color(0xFF58A6FF);
  static const accentGreen = Color(0xFF3FB950);
  static const accentRed = Color(0xFFF85149);
  static const accentYellow = Color(0xFFD29922);
  static const surfaceColor = Color(0xFF0A0A0A);
  static const primarySurface = Color(0xFF1C1C1E);
  static const secondarySurface = Color(0xFF2C2C2E);
  static const tertiaryColor = Color(0xFF3A3A3C);
  static const accentBlue = Color(0xFF007AFF);
  static const accentTeal = Color(0xFF5AC8FA);
  static const accentPurple = Color(0xFFAF52DE);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFEBEBF5);
  static const textTertiary = Color(0xFF8E8E93);
  static const textMuted = Color(0xFF6E7681);
}

class AppTheme {
  ThemeData get ultraDarkTheme {
    const surfaceColor = AppColors.surfaceColor;
    const primarySurface = AppColors.primarySurface;
    const secondarySurface = AppColors.secondarySurface;
    const tertiaryColor = AppColors.tertiaryColor;
    const accentBlue = AppColors.accentBlue;
    const accentTeal = AppColors.accentTeal;
    const accentPurple = AppColors.accentPurple;
    const textPrimary = AppColors.textPrimary;
    const textSecondary = AppColors.textSecondary;
    const textTertiary = AppColors.textTertiary;

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: accentBlue,
        onPrimary: textPrimary,
        primaryContainer: Color(0xFF1D4ED8),
        onPrimaryContainer: textPrimary,
        secondary: accentTeal,
        onSecondary: textPrimary,
        secondaryContainer: Color(0xFF0891B2),
        onSecondaryContainer: textPrimary,
        tertiary: accentPurple,
        onTertiary: textPrimary,
        tertiaryContainer: Color(0xFF7C3AED),
        onTertiaryContainer: textPrimary,
        error: Color(0xFFFF453A),
        onError: textPrimary,
        errorContainer: Color(0xFF8B0000),
        onErrorContainer: textPrimary,
        outline: Color(0xFF545458),
        outlineVariant: Color(0xFF3A3A3C),
        surface: surfaceColor,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        inverseSurface: textPrimary,
        onInverseSurface: surfaceColor,
        inversePrimary: accentBlue,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: accentBlue,
        surfaceContainerHighest: tertiaryColor,
        surfaceContainerHigh: secondarySurface,
        surfaceContainer: primarySurface,
        surfaceContainerLow: Color(0xFF161618),
        surfaceContainerLowest: Color(0xFF0C0C0E),
        surfaceBright: primarySurface,
        surfaceDim: Color(0xFF1A1A1C),
      ),

      // Text theme
      textTheme: textTheme,

      // App Bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: textPrimary, size: 22),
      ),

      // Card theme
      cardTheme: const CardThemeData(
        color: primarySurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentBlue,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primarySurface.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: tertiaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF453A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF453A), width: 2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        errorStyle: textTheme.bodySmall?.copyWith(
          color: const Color(0xFFFF453A),
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: accentBlue.withValues(alpha: 0.1),
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: primarySurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: primarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // Floating Action Button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: textPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: tertiaryColor.withValues(alpha: 0.3),
        thickness: 0.5,
        space: 1,
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentBlue;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(textPrimary),
        side: const BorderSide(color: textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // Snack bar theme - Ultra stylé  style
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primarySurface.withValues(alpha: 0.95),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: tertiaryColor.withValues(alpha: 0.3), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        actionTextColor: accentBlue,
        closeIconColor: textSecondary,
        showCloseIcon: false,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        dismissDirection: DismissDirection.horizontal,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentBlue,
        linearTrackColor: tertiaryColor,
        circularTrackColor: tertiaryColor,
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: accentBlue,
        inactiveTrackColor: tertiaryColor,
        thumbColor: accentBlue,
        overlayColor: accentBlue.withValues(alpha: 0.2),
        valueIndicatorColor: accentBlue,
        valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(
          color: textPrimary,
        ),
      ),
    );
  }
}
