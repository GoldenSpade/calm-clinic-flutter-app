import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (pastel pink/rose)
  static const Color primary = Color(0xFFD186A6); // hsl(340 60% 75%)
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Background colors
  static const Color background = Color(0xFFF5E8EE); // hsl(320 50% 96%)
  static const Color foreground = Color(0xFF475569); // hsl(215 25% 25%)

  // Card colors
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF475569);

  // Secondary & Muted colors
  static const Color secondary = Color(0xFFD9CADF); // hsl(280 30% 85%)
  static const Color muted = Color(0xFFE5F2ED); // hsl(160 25% 92%)
  static const Color mutedForeground = Color(0xFF64748B); // hsl(215 15% 50%)

  // Accent colors
  static const Color sage = Color(0xFFD5E9DC); // hsl(140 35% 85%)
  static const Color lavender = Color(0xFFE8DDEF); // hsl(280 45% 90%)
  static const Color peach = Color(0xFFF7E5D9); // hsl(20 70% 90%)

  // Border & Input
  static const Color border = Color(0xFFE8D9ED); // hsl(280 30% 90%)
  static const Color input = Color(0xFFE8D9ED);

  // Shadows (using alpha for transparency)
  static final Color shadowSoft = AppColors.primary.withValues(alpha: 0.15);
  static final Color shadowCard = AppColors.primary.withValues(alpha: 0.20);
  static final Color shadowPremium = AppColors.primary.withValues(alpha: 0.30);

  // Gradients
  static const LinearGradient gradientSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF5E8EE), // hsl(320 50% 96%)
      Color(0xFFF0E4F0), // hsl(280 30% 95%)
    ],
  );

  static const LinearGradient gradientPremium = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE5C4D7), // hsl(340 60% 85%)
      Color(0xFFDFCDE8), // hsl(280 50% 88%)
    ],
  );

  static const LinearGradient gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF7F0F7), // hsl(280 30% 98%)
    ],
  );
}
