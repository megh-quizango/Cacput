import 'package:flutter/material.dart';

class AppColors {
  // Primary Obsidian & Midnight Canvas Palette
  static const Color studioBlack = Color(0xFF080810);
  static const Color canvasBackground = Color(0xFF090911);
  static const Color darkCanvas = Color(0xFF0A0A12);
  static const Color cardSurface = Color(0xFF161622);
  static const Color cardSurfaceLight = Color(0xFF1B1B2A);
  static const Color cardBorder = Color(0xFF252538);
  static const Color subtleDivider = Color(0xFF1E1E2D);

  // Vibrant Accents
  static const Color brandPink = Color(0xFFFF2A6D);
  static const Color brandPinkAccent = Color(0xFFFE2C55);
  static const Color brandPinkLight = Color(0xFFFF4267);
  static const Color brandCyan = Color(0xFF00E5FF);
  static const Color brandCyanAccent = Color(0xFF00DF9A);
  static const Color brandGold = Color(0xFFFFB800);
  static const Color brandGreen = Color(0xFF00E676);
  static const Color brandPurple = Color(0xFF8A2BE2);
  static const Color brandBlue = Color(0xFF2979FF);

  // Quick Tools Tints
  static const Color toolGreenBg = Color(0xFF06241D);
  static const Color toolGreenBorder = Color(0xFF0E5C47);
  static const Color toolPinkBg = Color(0xFF2B0E1E);
  static const Color toolPinkBorder = Color(0xFF6E1843);
  static const Color toolGoldBg = Color(0xFF291B07);
  static const Color toolGoldBorder = Color(0xFF6B470E);
  static const Color toolPurpleBg = Color(0xFF1B132E);
  static const Color toolPurpleBorder = Color(0xFF4B2A82);

  // Typography Palette
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA0A5BA);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF4A4A62);

  // Button & Input States
  static const Color buttonDisabled = Color(0xFF222232);
  static const Color buttonDisabledText = Color(0xFF5A5A72);
  static const Color inputBorderInactive = Color(0xFF33334A);

  // Gradients
  static const LinearGradient heroPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF3366),
      Color(0xFFFF4267),
      Color(0xFFFF5E8A),
    ],
  );

  static const LinearGradient heroCyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00E5FF),
      Color(0xFF00B0FF),
    ],
  );

  static const LinearGradient cardDarkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF1B1B2A),
      Color(0xFF141421),
    ],
  );

  static const RadialGradient ambientGlow = RadialGradient(
    center: Alignment(0.8, -0.6),
    radius: 0.9,
    colors: [
      Color(0x33FF2A6D),
      Color(0x00090911),
    ],
  );
}
