import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable pure-glassmorphism card.
///
/// Architecture:
///   RepaintBoundary          ← isolates repaints for performance
///     ClipRRect              ← clips blur to the card's round corners
///       BackdropFilter       ← blurs everything rendered behind this widget
///         Container          ← semi-transparent surface + glass border + shadow
///
/// Usage:
///   GlassCard(child: MyContent())
///   GlassCard.strong(child: MyContent())  ← slightly more opaque variant
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(GlassTokens.radius)),
    this.blur = GlassTokens.blurSigma,
    this.backgroundColor = GlassTokens.cardBg,
    this.borderColor = GlassTokens.cardBorder,
    this.boxShadow,
  });

  /// Slightly more opaque variant for elevated elements (modals, panels).
  const GlassCard.strong({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(GlassTokens.radius)),
    this.blur = GlassTokens.blurSigmaHeavy,
    this.backgroundColor = GlassTokens.cardBgStrong,
    this.borderColor = GlassTokens.cardBorderHi,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final shadows = boxShadow ?? GlassTokens.cardShadow;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
              border: Border.all(color: borderColor, width: 1),
              boxShadow: shadows,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
