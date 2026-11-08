import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

/// Trickster's design tokens, trimmed to what this window paints.
abstract final class ShellBrandColors {
  static const Color defaultAccent = Color(0xffd0bcff);
}

abstract final class ShellMediaColors {
  static const Color lightForeground = Color(0xfff7f7f8);
  static const Color lightForegroundSecondary = Color(0xffc7c9d1);
  static const Color darkness = Color(0xff000000);
}

abstract final class ShellTelemetryColors {
  static const Color warning = Color(0xffffd166);
  static const Color danger = Color(0xffff6b6b);
  static const Color nominal = Color(0xff8ee6c1);
}

abstract final class ShellText {
  static const String systemBarFontFamily = 'JetBrainsMono';
  static const List<String> fallbackFontFamilies = <String>[
    'JetBrains Mono',
    'Source Han Sans CN',
    'Noto Sans CJK SC',
  ];

  static const TextStyle systemBarValue = TextStyle(
    fontFamily: systemBarFontFamily,
    fontFamilyFallback: fallbackFontFamilies,
    fontSize: 13,
    height: 1,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    decoration: TextDecoration.none,
    color: ShellMediaColors.lightForeground,
  );

  static const TextStyle systemBarCaption = TextStyle(
    fontFamily: systemBarFontFamily,
    fontFamilyFallback: fallbackFontFamilies,
    fontSize: 11,
    height: 1,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    decoration: TextDecoration.none,
  );
}

abstract final class Motion {
  static const Duration cardSettle = Duration(milliseconds: 220);
  static const Duration wallpaperReveal = Duration(milliseconds: 720);
  static const Duration workspaceSwitch = Duration(milliseconds: 320);
  static const Curve standard = Curves.easeOutCubic;
}

/// Trickster's accent model: one color, tinted card fills, muted captions.
@immutable
class WallpaperAccent {
  const WallpaperAccent(this.color, {this.isResolved = true});

  static const WallpaperAccent fallback = WallpaperAccent(
    ShellBrandColors.defaultAccent,
    isResolved: false,
  );

  final Color color;
  final bool isResolved;

  Color cardFill() => Color.lerp(const Color(0xff1c1b22), color, 0.15)!;

  Color cardFillTop() => Color.lerp(const Color(0xff1c1b22), color, 0.24)!;

  Color captionColor() =>
      Color.lerp(ShellMediaColors.lightForegroundSecondary, color, 0.35)!;

  @override
  bool operator ==(Object other) =>
      other is WallpaperAccent &&
      other.color == color &&
      other.isResolved == isResolved;

  @override
  int get hashCode => Object.hash(color, isResolved);
}

Color? colorFromHex(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  var hex = value;
  if (hex.startsWith('#')) {
    hex = hex.substring(1);
  }
  if (hex.length != 6) {
    return null;
  }
  final parsed = int.tryParse(hex, radix: 16);
  return parsed == null ? null : Color(0xff000000 | parsed);
}

/// Reads the accent Trickster's own document carries, so the companion window
/// shares the bar's color. Wallpaper sampling stays inside the bar; this uses
/// the configured accent (or the brand default).
WallpaperAccent loadTricksterAccent({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  try {
    final config = env['XDG_CONFIG_HOME'];
    final home = env['HOME'] ?? '';
    final base = config == null || config.isEmpty ? '$home/.config' : config;
    final file = File('$base/trickster/settings.json');
    if (!file.existsSync()) {
      return WallpaperAccent.fallback;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      return WallpaperAccent.fallback;
    }
    final color = colorFromHex(decoded['accent']);
    return color == null ? WallpaperAccent.fallback : WallpaperAccent(color);
  } on Object {
    return WallpaperAccent.fallback;
  }
}

ThemeData tricksterTheme(WallpaperAccent accent) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent.color,
    brightness: Brightness.dark,
    surface: const Color(0xff0b0b0f),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ShellMediaColors.darkness,
    fontFamily: ShellText.systemBarFontFamily,
    fontFamilyFallback: ShellText.fallbackFontFamilies,
    splashFactory: NoSplash.splashFactory,
    visualDensity: VisualDensity.standard,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontFamily: ShellText.systemBarFontFamily,
        fontFamilyFallback: ShellText.fallbackFontFamilies,
        fontSize: 13,
        color: ShellMediaColors.lightForeground,
      ),
      bodySmall: TextStyle(
        fontFamily: ShellText.systemBarFontFamily,
        fontFamilyFallback: ShellText.fallbackFontFamilies,
        fontSize: 11,
        color: ShellMediaColors.lightForegroundSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: ShellText.systemBarFontFamily,
        fontFamilyFallback: ShellText.fallbackFontFamilies,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
        color: ShellMediaColors.lightForegroundSecondary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: ShellMediaColors.lightForegroundSecondary,
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: accent.cardFill().withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.color.withValues(alpha: 0.2)),
      ),
      textStyle: ShellText.systemBarCaption.copyWith(
        color: ShellMediaColors.lightForeground,
      ),
    ),
  );
}
