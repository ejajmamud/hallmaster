import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

// Re-export tokens so existing imports of
// `package:hallmaster_enterprise/src/app/theme.dart` keep resolving
// `AppTokens`, `StatusIntent`, `ColorPair`, etc.
export 'tokens.dart';

/// Builds the HallMaster Enterprise Material 3 theme.
///
/// Visual direction: "municipal operations cockpit" — restrained navy,
/// cool near-white canvas, one accent, serious typography, subtle motion.
ThemeData buildHallMasterTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppTokens.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppTokens.brand,
    onPrimary: AppTokens.textInverse,
    primaryContainer: AppTokens.brandSurfaceStrong,
    onPrimaryContainer: AppTokens.brandInk,
    secondary: AppTokens.info,
    onSecondary: AppTokens.textInverse,
    secondaryContainer: AppTokens.infoSurface,
    onSecondaryContainer: AppTokens.onInfoSurface,
    surface: AppTokens.cardSurface,
    onSurface: AppTokens.textPrimary,
    outline: AppTokens.borderStrong,
    outlineVariant: AppTokens.border,
    error: AppTokens.danger,
    onError: AppTokens.textInverse,
    errorContainer: AppTokens.dangerSurface,
    onErrorContainer: AppTokens.onDangerSurface,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(_buildTextTheme());

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    scaffoldBackgroundColor: AppTokens.canvas,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTokens.canvas,
      foregroundColor: AppTokens.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: AppTokens.s3,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: AppTokens.wExtraBold,
        letterSpacing: -0.3,
        color: AppTokens.textPrimary,
      ),
      toolbarTextStyle: TextStyle(
        color: AppTokens.textPrimary,
        fontWeight: AppTokens.wMedium,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: AppTokens.elev0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: const BorderSide(color: AppTokens.border),
      ),
      color: AppTokens.cardSurface,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: AppTokens.s2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppTokens.cardSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppTokens.brandSurface,
      indicatorShape: const StadiumBorder(),
      labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(MaterialState.selected)
              ? AppTokens.wBold
              : AppTokens.wMedium,
          color: states.contains(MaterialState.selected)
              ? AppTokens.brand
              : AppTokens.textSecondary,
          letterSpacing: 0.1,
        ),
      ),
      iconTheme: MaterialStateProperty.resolveWith<IconThemeData>(
        (states) => IconThemeData(
          size: 22,
          color: states.contains(MaterialState.selected)
              ? AppTokens.brand
              : AppTokens.textSecondary,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      hintStyle: const TextStyle(color: AppTokens.textTertiary),
      labelStyle: const TextStyle(color: AppTokens.textSecondary),
      floatingLabelStyle: const TextStyle(
        color: AppTokens.brand,
        fontWeight: AppTokens.wSemibold,
      ),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3 + 2, vertical: AppTokens.s3 + 2),
      filled: true,
      fillColor: AppTokens.elevatedSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.border, width: 1.1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.border, width: 1.1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.brand, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.danger, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        borderSide: const BorderSide(color: AppTokens.danger, width: 1.6),
      ),
      errorStyle: const TextStyle(
        color: AppTokens.danger,
        fontWeight: AppTokens.wSemibold,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppTokens.brandInk,
      contentTextStyle: const TextStyle(
        color: AppTokens.textInverse,
        fontWeight: AppTokens.wMedium,
      ),
      actionTextColor: AppTokens.brandSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      insetPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s4, vertical: AppTokens.s3),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: AppTokens.brand,
        foregroundColor: AppTokens.textInverse,
        disabledBackgroundColor: AppTokens.brandSurface,
        disabledForegroundColor: AppTokens.textDisabled,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s5, vertical: AppTokens.s3 + 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm + 2),
        ),
        textStyle: const TextStyle(
          fontWeight: AppTokens.wBold,
          fontSize: 15,
          letterSpacing: -0.05,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: AppTokens.brand,
        side: const BorderSide(color: AppTokens.borderStrong, width: 1.2),
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s5, vertical: AppTokens.s3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm + 2),
        ),
        textStyle: const TextStyle(
          fontWeight: AppTokens.wBold,
          fontSize: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppTokens.brand,
        padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s3, vertical: AppTokens.s2),
        textStyle: const TextStyle(fontWeight: AppTokens.wBold, fontSize: 14),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppTokens.textSecondary,
        hoverColor: AppTokens.brandSurface,
        focusColor: AppTokens.brandSurface,
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      backgroundColor: AppTokens.brandSurface,
      selectedColor: AppTokens.brandSurfaceStrong,
      disabledColor: AppTokens.canvasTint,
      side: const BorderSide(color: AppTokens.border),
      labelStyle: const TextStyle(
        fontWeight: AppTokens.wSemibold,
        color: AppTokens.brandInk,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: AppTokens.wSemibold,
        color: AppTokens.brandInk,
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s3, vertical: AppTokens.s1),
    ),
    dividerTheme: const DividerThemeData(
      color: AppTokens.divider,
      thickness: 1,
      space: 1,
    ),
    dividerColor: AppTokens.divider,
    dialogTheme: DialogThemeData(
      backgroundColor: AppTokens.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppTokens.elev3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppTokens.textPrimary,
        height: 1.5,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppTokens.brand,
      unselectedLabelColor: AppTokens.textSecondary,
      labelStyle: const TextStyle(fontWeight: AppTokens.wBold, fontSize: 14),
      unselectedLabelStyle:
          const TextStyle(fontWeight: AppTokens.wMedium, fontSize: 14),
      indicatorSize: TabBarIndicatorSize.label,
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: AppTokens.brand, width: 2.5),
      ),
      overlayColor: MaterialStateProperty.all(AppTokens.brandSurface),
      dividerColor: AppTokens.divider,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppTokens.cardSurface,
      surfaceTintColor: Colors.transparent,
      elevation: AppTokens.elev4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusSm + 2),
        side: const BorderSide(color: AppTokens.border),
      ),
      textStyle: const TextStyle(
        fontWeight: AppTokens.wMedium,
        color: AppTokens.textPrimary,
        fontSize: 14,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: const TextStyle(
        color: AppTokens.textInverse,
        fontWeight: AppTokens.wSemibold,
        fontSize: 12,
      ),
      decoration: BoxDecoration(
        color: AppTokens.brandInk,
        borderRadius: BorderRadius.circular(AppTokens.radiusXs),
      ),
      waitDuration: const Duration(milliseconds: 400),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppTokens.s4),
      iconColor: AppTokens.textSecondary,
      textColor: AppTokens.textPrimary,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: AppTokens.wSemibold,
        color: AppTokens.textPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: 13,
        color: AppTokens.textSecondary,
        height: 1.45,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppTokens.brand,
      foregroundColor: AppTokens.textInverse,
      elevation: AppTokens.elev3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      ),
    ),
  );
}

TextTheme _buildTextTheme() {
  // Typography scale — deliberately tighter than Material defaults so
  // dense operational screens read without feeling shouty.
  return const TextTheme(
    displayLarge: TextStyle(
      fontSize: 44,
      fontWeight: AppTokens.wExtraBold,
      letterSpacing: -0.8,
      color: AppTokens.textPrimary,
      height: 1.1,
    ),
    displayMedium: TextStyle(
      fontSize: 36,
      fontWeight: AppTokens.wExtraBold,
      letterSpacing: -0.6,
      color: AppTokens.textPrimary,
      height: 1.15,
    ),
    displaySmall: TextStyle(
      fontSize: 30,
      fontWeight: AppTokens.wExtraBold,
      letterSpacing: -0.5,
      color: AppTokens.textPrimary,
      height: 1.2,
    ),
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: AppTokens.wExtraBold,
      letterSpacing: -0.45,
      color: AppTokens.textPrimary,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 24,
      fontWeight: AppTokens.wExtraBold,
      letterSpacing: -0.35,
      color: AppTokens.textPrimary,
      height: 1.22,
    ),
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: AppTokens.wBold,
      letterSpacing: -0.2,
      color: AppTokens.textPrimary,
      height: 1.25,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: AppTokens.wBold,
      letterSpacing: -0.15,
      color: AppTokens.textPrimary,
      height: 1.3,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: AppTokens.wBold,
      letterSpacing: -0.1,
      color: AppTokens.textPrimary,
      height: 1.35,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: AppTokens.wBold,
      color: AppTokens.textPrimary,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 1.5,
      color: AppTokens.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 1.5,
      color: AppTokens.textSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      height: 1.45,
      color: AppTokens.textTertiary,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: AppTokens.wBold,
      letterSpacing: 0.1,
      color: AppTokens.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 13,
      fontWeight: AppTokens.wSemibold,
      letterSpacing: 0.15,
      color: AppTokens.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11.5,
      fontWeight: AppTokens.wSemibold,
      letterSpacing: 0.4,
      color: AppTokens.textSecondary,
    ),
  );
}
