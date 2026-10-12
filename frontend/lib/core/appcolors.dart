import 'package:flutter/material.dart';

/// Centralized color palette for the Live Loop application
class AppColors {
  // Base & Surface Colors
  static const Color transparent = Colors.transparent;
  static const Color background = Color(0xFF0B0F19);
  static const Color surface = Color(0xFF171A24);
  static const Color inputFill = Color(0xFF171A24);
  static const Color cardBackground = Color(0xFF171A24);

  // Primary & Accent Colors
  static const Color primary = Color(0xFF4F46E5);
  static Color get primaryDisabled => const Color(0xFF4F46E5).withValues(alpha: 0.6);
  static const Color primaryGradientStart = Color(0xFF5748EF);
  static const Color primaryGradientEnd = Color(0xFF4B3BD9);

  // Text & Content Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color hintText = Color(0xFF9E9E9E);
  static const Color iconColor = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFF9E9E9E);

  // Avatar Colors
  static const Color avatarBackground = Color.fromARGB(77, 66, 66, 66);

  // Bottom Navigation Colors
  static const Color navigationBackground = Color(0xFF1E293B);
  static const Color navigationBorder = Color(0xFF2D3B50);
  static const Color selectedBackground = Color(0xFF29265D);
  static const Color selectedText = Color(0xFF6255FF);
  static const Color inactiveText = Color(0xFF94A3B8);

  // Feedback & Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFF9800);

  // Common Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      primaryGradientStart,
      primaryGradientEnd,
    ],
  );
   static Color liveGreen = Color(0xFF22C55E);
}