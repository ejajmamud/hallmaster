import 'package:flutter/material.dart';

/// HallMaster Enterprise design tokens.
///
/// Single source of truth for spacing, radius, typography weights,
/// color semantics, motion timing, elevation, and responsive breakpoints.
///
/// This class is intentionally pure data + small helpers so it can be
/// imported by `theme.dart` and consumed directly by widgets that need
/// tokens outside of `ThemeData` (e.g. custom chips, spacing rows).
///
/// Legacy aliases (radiusSm/radiusMd/radiusLg/radiusXl, pagePadding,
/// cardPadding, brand/brandInk/textPrimary/textSecondary/brandSurface,
/// canvas/cardSurface/canvasTint, danger/dangerSurface/warning/warningSurface)
/// are preserved so existing screen files compile without edits.
class AppTokens {
  AppTokens._();

  // ───────────────── Spacing (4pt rhythm) ─────────────────
  static const double s0 = 0;
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s7 = 32;
  static const double s8 = 40;
  static const double s9 = 56;

  static const EdgeInsets pagePadding = EdgeInsets.all(s4);
  static const EdgeInsets cardPadding = EdgeInsets.all(s4);
  static const EdgeInsets sectionPadding =
      EdgeInsets.symmetric(horizontal: s4, vertical: s3);
  static const EdgeInsets listItemPadding = EdgeInsets.fromLTRB(s4, s3, s3, s3);

  // ───────────────── Radius ─────────────────
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  // ───────────────── Typography weights ─────────────────
  // Keep the weight set compact so the global type system stays crisp.
  static const FontWeight wRegular = FontWeight.w400;
  static const FontWeight wMedium = FontWeight.w500;
  static const FontWeight wSemibold = FontWeight.w600;
  static const FontWeight wBold = FontWeight.w700;
  static const FontWeight wExtraBold = FontWeight.w800;

  // ───────────────── Motion ─────────────────
  static const Duration motionFast = Duration(milliseconds: 120);
  static const Duration motionBase = Duration(milliseconds: 200);
  static const Duration motionSlow = Duration(milliseconds: 280);
  static const Duration motionXSlow = Duration(milliseconds: 420);

  static const Curve easeStandard = Curves.easeInOutCubic;
  static const Curve easeEntrance = Curves.easeOutCubic;
  static const Curve easeExit = Curves.easeInCubic;
  static const Curve easeEmphasized = Cubic(0.2, 0.0, 0.0, 1.0);

  // ───────────────── Responsive breakpoints ─────────────────
  static const double bpCompact = 0;
  static const double bpMedium = 600;
  static const double bpExpanded = 840;
  static const double bpLarge = 1200;

  /// Returns a semantic layout tier from the current width.
  static LayoutTier tierFor(double width) {
    if (width >= bpLarge) return LayoutTier.large;
    if (width >= bpExpanded) return LayoutTier.expanded;
    if (width >= bpMedium) return LayoutTier.medium;
    return LayoutTier.compact;
  }

  // ───────────────── Elevation ─────────────────
  // We use subtle ambient shadows only — no heavy drop shadows.
  static const double elev0 = 0;
  static const double elev1 = 1; // card resting
  static const double elev2 = 2; // card hovered
  static const double elev3 = 4; // dialogs / sheets
  static const double elev4 = 8; // menus / toasts

  // ───────────────── Color palette ─────────────────
  // Brand — restrained municipal-grade navy.
  static const Color brand = Color(0xFF0A57C7);
  static const Color brandHover = Color(0xFF084BA9);
  static const Color brandPressed = Color(0xFF063E8A);
  static const Color brandInk = Color(0xFF081E42);
  static const Color brandSurface = Color(0xFFE6EFFF);
  static const Color brandSurfaceStrong = Color(0xFFD9E6FF);

  // Accent — warm, CelcomDigi-like highlight used sparingly.
  static const Color accent = Color(0xFFD6A12D);
  static const Color accentStrong = Color(0xFFAA7A16);
  static const Color accentSurface = Color(0xFFFFF3D7);
  static const Color onAccentSurface = Color(0xFF725100);

  // Surfaces — cool, near-white, operational.
  static const Color canvas = Color(0xFFF4F7FC);
  static const Color canvasTint = Color(0xFFEAF1FB);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color elevatedSurface = Color(0xFFFBFCFE);

  // Text
  static const Color textPrimary = Color(0xFF081322);
  static const Color textSecondary = Color(0xFF33415B);
  static const Color textTertiary = Color(0xFF56637C);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textDisabled = Color(0xFF97A1B4);

  // Borders & dividers
  static const Color border = Color(0xFFCBD6E4);
  static const Color borderStrong = Color(0xFFAAB8CC);
  static const Color divider = Color(0xFFE2E8F1);

  // Semantic statuses — accessible against their *Surface companion (>= 4.5:1).
  static const Color danger = Color(0xFFB42318);
  static const Color dangerStrong = Color(0xFF8F1C13);
  static const Color dangerSurface = Color(0xFFFEE4E2);
  static const Color onDangerSurface = Color(0xFF7A140C);

  static const Color warning = Color(0xFF9A5A00);
  static const Color warningStrong = Color(0xFF7A4600);
  static const Color warningSurface = Color(0xFFFFF4E5);
  static const Color onWarningSurface = Color(0xFF7A4600);

  static const Color success = Color(0xFF196B3D);
  static const Color successStrong = Color(0xFF105530);
  static const Color successSurface = Color(0xFFE6F6EE);
  static const Color onSuccessSurface = Color(0xFF0D4A2A);

  static const Color info = Color(0xFF254F91);
  static const Color infoSurface = Color(0xFFE8EEF9);
  static const Color onInfoSurface = Color(0xFF1B3A6B);

  // ───────────────── Status helpers ─────────────────
  /// Returns a (background, foreground) color pair for a given
  /// semantic intent, guaranteed to meet WCAG 2.1 AA contrast.
  static ColorPair statusColors(StatusIntent intent) {
    switch (intent) {
      case StatusIntent.success:
        return const ColorPair(bg: successSurface, fg: onSuccessSurface);
      case StatusIntent.warning:
        return const ColorPair(bg: warningSurface, fg: onWarningSurface);
      case StatusIntent.danger:
        return const ColorPair(bg: dangerSurface, fg: onDangerSurface);
      case StatusIntent.info:
        return const ColorPair(bg: infoSurface, fg: onInfoSurface);
      case StatusIntent.neutral:
        return const ColorPair(bg: brandSurface, fg: brandInk);
    }
  }
}

enum LayoutTier { compact, medium, expanded, large }

enum StatusIntent { success, warning, danger, info, neutral }

class ColorPair {
  const ColorPair({required this.bg, required this.fg});
  final Color bg;
  final Color fg;
}
