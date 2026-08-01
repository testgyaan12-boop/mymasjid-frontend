import 'package:flutter/material.dart';

class HSLColorConverter {
  static Color fromHslString(String hsl, [double alpha = 1.0]) {
    try {
      final parts = hsl.replaceAll('%', '').split(' ');
      if (parts.length >= 3) {
        final h = double.parse(parts[0]);
        final s = double.parse(parts[1]) / 100;
        final l = double.parse(parts[2]) / 100;
        return HSLColor.fromAHSL(alpha, h, s, l).toColor();
      }
    } catch (_) {}
    return Colors.green;
  }
}

class AppColors {
  // Light theme (matches globals.css :root)
  static const Color lightBackground = Color(0xFFF2F7F2);
  static const Color lightForeground = Color(0xFF0F1C10);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFE3EDE4);
  static const Color lightMutedForeground = Color(0xFF3D5C3F);
  static const Color lightBorder = Color(0xFFCDE0CF);

  // Dark theme
  static const Color darkBackground = Color(0xFF0A140B);
  static const Color darkForeground = Color(0xFFE8F0E8);
  static const Color darkCard = Color(0xFF152316);
  static const Color darkMuted = Color(0xFF1C2E1D);
  static const Color darkMutedForeground = Color(0xFFA0B8A2);
  static const Color darkBorder = Color(0xFF1C2E1D);

  // Primary (Sage Green - default)
  static const Color primaryLight = Color(0xFFA8C6AA);
  static const Color primaryDark = Color(0xFF5C8C5F);
  static const Color primaryForeground = Color(0xFF0F1C10);

  // Secondary (Gold/Amber)
  static const Color secondaryLight = Color(0xFFD6A23B);
  static const Color secondaryDark = Color(0xFFC4922E);
  static const Color secondaryForeground = Color(0xFF1A1A1A);

  // Destructive
  static const Color destructive = Color(0xFFE55353);

  static const Color gold = Color(0xFFD6A23B);
  static const Color amber = Color(0xFFD4A843);
}

class ThemePreset {
  final String name;
  final String primaryHsl;
  final String secondaryHsl;

  const ThemePreset(this.name, this.primaryHsl, this.secondaryHsl);

  static const List<ThemePreset> presets = [
    ThemePreset('Emerald (Classic)', '142 76% 36%', '43 76% 58%'),
    ThemePreset('Sapphire (Modern)', '217 91% 60%', '199 89% 48%'),
    ThemePreset('Gold (Premium)', '43 76% 58%', '32 95% 44%'),
    ThemePreset('Ruby (Spiritual)', '0 72% 51%', '354 70% 40%'),
    ThemePreset('Midnight (Deep)', '222 47% 11%', '210 40% 96%'),
    ThemePreset('Amethyst (Royal)', '262 83% 58%', '280 67% 45%'),
    ThemePreset('Forest (Peace)', '160 84% 39%', '142 71% 45%'),
    ThemePreset('Ocean (Calm)', '199 89% 48%', '180 100% 35%'),
    ThemePreset('Sand (Desert)', '32 95% 44%', '43 76% 58%'),
  ];
}
