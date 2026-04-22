import 'package:flutter/material.dart';

/// Bảng màu chủ đạo: Xanh biển pastel (Ocean Pastel)
class AppColors {
  AppColors._();

  // ── Primary palette ──────────────────────────────────────────
  /// Xanh biển pastel chính
  static const Color primary = Color(0xFF5B9BD5);

  /// Xanh nhạt hơn – hover, chip selected
  static const Color primaryLight = Color(0xFF85B9E8);

  /// Xanh rất nhạt – background tint, container fill
  static const Color primarySurface = Color(0xFFE8F2FB);

  /// Xanh đậm – pressed state, text emphasis
  static const Color primaryDark = Color(0xFF3A7DBF);

  // ── Secondary / Accent ───────────────────────────────────────
  /// Xanh mint – accent thứ cấp, highlight
  static const Color secondary = Color(0xFF6EC6CA);

  /// Tím lavender nhạt – pomodoro / focus mode
  static const Color pomodoro = Color(0xFFB5A5E0);

  /// Đỏ san hô – lỗi, deadline gấp, priority cao
  static const Color danger = Color(0xFFFF6B6B);

  /// Xanh lá sage – hoàn thành, success
  static const Color success = Color(0xFF6BCB77);

  /// Vàng amber – warning, priority medium
  static const Color warning = Color(0xFFFFB347);

  // ── Neutral ──────────────────────────────────────────────────
  static const Color background = Color(0xFFF5F9FE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEAF3FC);

  static const Color textPrimary = Color(0xFF0E1E2D);
  static const Color textSecondary = Color(0xFF4A6A8A);
  static const Color textHint = Color(0xFF90AECC);

  static const Color divider = Color(0xFFD0E4F5);
  static const Color border = Color(0xFFBDD5ED);

  // ── Priority mapping ─────────────────────────────────────────
  static const Color priorityHigh = Color(0xFFFF6B6B);
  static const Color priorityMedium = Color(0xFFFFB347);
  static const Color priorityLow = Color(0xFF6BCB77);

  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return priorityHigh;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  // ── Gradient helpers ─────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5B9BD5), Color(0xFF85B9E8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient oceanGradient = LinearGradient(
    colors: [Color(0xFF3A7DBF), Color(0xFF6EC6CA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Theme helpers ─────────────────────────────────────────────
  static ColorScheme get colorScheme => ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primarySurface,
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        outline: border,
        error: danger,
      );
}