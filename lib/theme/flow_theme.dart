import 'package:flutter/material.dart';

import 'flow_colors.dart';
import 'flow_font.dart';
import 'flow_tokens.dart';

abstract final class FlowTheme {
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData dark() => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? FlowColors.darkBackground
        : FlowColors.lightBackground;
    final surface = isDark ? FlowColors.darkSurface : FlowColors.lightSurface;
    final text = isDark ? FlowColors.darkText : FlowColors.lightText;
    final mutedText = isDark
        ? FlowColors.darkMutedText
        : FlowColors.lightMutedText;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: FlowColors.accent,
      onPrimary: Colors.white,
      secondary: FlowColors.accent,
      onSecondary: Colors.white,
      error: FlowColors.destructive,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      outline: isDark ? const Color(0xFF3D4A46) : const Color(0xFFD9DFDC),
      surfaceContainerHighest: isDark
          ? const Color(0xFF2C3532)
          : const Color(0xFFEFF1EE),
    );
    final textTheme = _textTheme(text, mutedText);

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme: textTheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: FlowColors.accent.withValues(
          alpha: isDark ? 0.24 : 0.14,
        ),
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        height: FlowControlSize.minTouchTarget + FlowSpacing.md,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: FlowColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowRadii.button),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: FlowSpacing.md,
          vertical: FlowSpacing.sm,
        ),
        border: _inputBorder(colorScheme.outline),
        enabledBorder: _inputBorder(colorScheme.outline),
        focusedBorder: _inputBorder(FlowColors.accent, width: 2),
        errorBorder: _inputBorder(FlowColors.destructive),
        focusedErrorBorder: _inputBorder(FlowColors.destructive, width: 2),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(color: mutedText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, FlowControlSize.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FlowRadii.button),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowRadii.card),
        ),
      ),
      extensions: [
        FlowThemeExtension(
          shadows: isDark ? FlowShadows.darkCard : FlowShadows.card,
        ),
      ],
    );
  }

  static InputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(FlowRadii.input),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(Color text, Color mutedText) {
    final base = FlowFont.applyTo(ThemeData.light().textTheme);
    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        color: text,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        color: text,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: text,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: text,
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: text,
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: mutedText,
        fontSize: 12,
        height: 1.35,
      ),
      labelLarge: base.labelLarge?.copyWith(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: base.labelMedium?.copyWith(
        color: mutedText,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(color: mutedText, fontSize: 11),
    );
  }
}

class FlowThemeExtension extends ThemeExtension<FlowThemeExtension> {
  const FlowThemeExtension({required this.shadows});

  final List<BoxShadow> shadows;

  @override
  FlowThemeExtension copyWith({List<BoxShadow>? shadows}) =>
      FlowThemeExtension(shadows: shadows ?? this.shadows);

  @override
  FlowThemeExtension lerp(covariant FlowThemeExtension? other, double t) =>
      this;
}
