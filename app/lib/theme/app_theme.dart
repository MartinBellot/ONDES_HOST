import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette tokens ───────────────────────────────────────────────────────────
class AppColors {
  // Base surfaces
  static const background      = Color(0xFF0D1117);
  static const surface         = Color(0xFF161B22);
  static const surfaceVariant  = Color(0xFF1C2128);
  // Borders
  static const border          = Color(0xFF30363D);
  static const borderLight     = Color(0xFF21262D);
  // Status accents
  static const accent          = Color(0xFF58A6FF);
  static const accentGreen     = Color(0xFF3FB950);
  static const accentRed       = Color(0xFFF85149);
  static const accentYellow    = Color(0xFFD29922);
  // iOS-palette accents (kept for compatibility)
  static const surfaceColor        = Color(0xFF0A0A0A);
  static const primarySurface     = Color(0xFF1C1C1E);
  static const secondarySurface   = Color(0xFF2C2C2E);
  static const tertiaryColor      = Color(0xFF3A3A3C);
  static const accentBlue         = Color(0xFF007AFF);
  static const accentTeal         = Color(0xFF5AC8FA);
  static const accentPurple       = Color(0xFFAF52DE);
  // Text
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFFEBEBF5);
  static const textTertiary   = Color(0xFF8E8E93);
  static const textMuted      = Color(0xFF6E7681);
}

// ─── Glassmorphism design tokens ──────────────────────────────────────────────
class GlassTokens {
  /// White at 5 % opacity — default card background
  static const cardBg       = Color(0x0DFFFFFF);
  /// White at 10 % opacity — elevated / active card
  static const cardBgStrong = Color(0x1AFFFFFF);
  /// White at 8 % opacity — sidebar / panel
  static const sidebarBg   = Color(0x14FFFFFF);
  // Borders (glass edge refraction)
  static const cardBorder   = Color(0x1AFFFFFF); // white 10 %
  static const cardBorderHi = Color(0x33FFFFFF); // white 20 %
  // Blur sigma
  static const blurSigma      = 12.0;
  static const blurSigmaHeavy = 24.0;
  // Corner radii
  static const radius    = 16.0;
  static const radiusLg  = 20.0;
  static const radiusSm  = 10.0;
  // Soft diffuse shadow
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 32,
      offset: const Offset(0, 8),
    ),
  ];
}

// ─── Theme ────────────────────────────────────────────────────────────────────
class AppTheme {
  ThemeData get ultraDarkTheme {
    // ── Typography ────────────────────────────────────────────────────────
    // H1–H3 + CTA labels  →  Poppins  (personality, geometric weight)
    // Titles + body        →  Inter   (neutral, readable, native-feel)
    const p = GoogleFonts.poppins;
    const i = GoogleFonts.inter;

    final textTheme = TextTheme(
      // ── Display / Headings (Poppins) ──────────────────────────────────
      displayLarge: p(
        fontSize: 32, fontWeight: FontWeight.w700,
        letterSpacing: -0.5, color: AppColors.textPrimary,
      ),
      displayMedium: p(
        fontSize: 28, fontWeight: FontWeight.w600,
        letterSpacing: -0.3, color: AppColors.textPrimary,
      ),
      displaySmall: p(
        fontSize: 24, fontWeight: FontWeight.w600,
        letterSpacing: -0.2, color: AppColors.textPrimary,
      ),
      headlineLarge: p(
        fontSize: 22, fontWeight: FontWeight.w600,
        letterSpacing: -0.1, color: AppColors.textPrimary,
      ),
      headlineMedium: p(
        fontSize: 20, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      headlineSmall: p(
        fontSize: 18, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      // ── Titles (Inter) ────────────────────────────────────────────────
      titleLarge: i(
        fontSize: 17, fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: i(
        fontSize: 16, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      titleSmall: i(
        fontSize: 15, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      // ── Body (Inter) ──────────────────────────────────────────────────
      bodyLarge: i(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: i(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: i(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      // ── Labels (CTA → Poppins) ────────────────────────────────────────
      labelLarge: p(
        fontSize: 15, fontWeight: FontWeight.w600,
        letterSpacing: 0.2, color: AppColors.textPrimary,
      ),
      labelMedium: i(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
      labelSmall: i(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 0.2, color: AppColors.textTertiary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.inter().fontFamily,

      // ── Color scheme ──────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.accentBlue,
        onPrimary: AppColors.textPrimary,
        primaryContainer: Color(0xFF1D4ED8),
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.accentTeal,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: Color(0xFF0891B2),
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.accentPurple,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: Color(0xFF7C3AED),
        onTertiaryContainer: AppColors.textPrimary,
        error: Color(0xFFFF453A),
        onError: AppColors.textPrimary,
        errorContainer: Color(0xFF8B0000),
        onErrorContainer: AppColors.textPrimary,
        outline: Color(0xFF545458),
        outlineVariant: Color(0xFF3A3A3C),
        surface: AppColors.surfaceColor,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.surfaceColor,
        inversePrimary: AppColors.accentBlue,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: AppColors.accentBlue,
        surfaceContainerHighest: AppColors.tertiaryColor,
        surfaceContainerHigh: AppColors.secondarySurface,
        surfaceContainer: AppColors.primarySurface,
        surfaceContainerLow: Color(0xFF161618),
        surfaceContainerLowest: Color(0xFF0C0C0E),
        surfaceBright: AppColors.primarySurface,
        surfaceDim: Color(0xFF1A1A1C),
      ),

      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,

      // ── App bar ───────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: p(
          fontSize: 17, fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
      ),

      // ── Card: transparent — GlassCard handles its own decoration ──────
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(GlassTokens.radius)),
        ),
      ),

      // ── Elevated button (labelLarge → Poppins) ────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          ),
          textStyle: p(
            fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.2,
          ),
        ),
      ),

      // ── Text button ───────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          ),
          textStyle: i(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── Input decoration ──────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF), // glass-tinted fill
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: i(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textMuted),
        labelStyle: i(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        errorStyle: i(fontSize: 12, color: AppColors.accentRed),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: const BorderSide(color: GlassTokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.accentRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
      ),

      // ── List tile ─────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.accentBlue.withValues(alpha: 0.1),
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        titleTextStyle: i(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        subtitleTextStyle: i(fontSize: 13, color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GlassTokens.radius)),
      ),

      // ── Bottom sheet ──────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.primarySurface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.primarySurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // ── FAB ───────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: GlassTokens.cardBorder,
        thickness: 0.5,
        space: 1,
      ),

      // ── Navigation bar (mobile bottom nav) ────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return i(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: selected ? AppColors.accent : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.accent : AppColors.textMuted,
            size: 22,
          );
        }),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.accentBlue
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textPrimary),
        side: const BorderSide(color: AppColors.textTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      // ── Snack bar ─────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primarySurface.withValues(alpha: 0.95),
        contentTextStyle: i(
          fontSize: 14, fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          side: const BorderSide(color: GlassTokens.cardBorder),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        actionTextColor: AppColors.accentBlue,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      ),

      // ── Progress indicator ────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentBlue,
        linearTrackColor: AppColors.tertiaryColor,
        circularTrackColor: AppColors.tertiaryColor,
      ),

      // ── Slider ────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.accentBlue,
        inactiveTrackColor: AppColors.tertiaryColor,
        thumbColor: AppColors.accentBlue,
        overlayColor: AppColors.accentBlue.withValues(alpha: 0.2),
      ),
    );
  }
}
