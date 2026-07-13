import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  static const Color brandBlue = Color(0xFF0000CD);
  static const Color brandBlueGlow = Color(0xFF2E45FF);
  static const Color brandBlueSoft = Color(0xFFD9D9F8);
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandGray = Color(0xFFD3D3D3);
  static const Color income = Color(0xFF1FAE6B);
  static const Color expense = Color(0xFFE5484D);
  static const Color reserved = Color(0xFF6C63FF);
  static const Color neutralData = Color(0xFFF2A93B);
  static const List<String> _fontFallback = [
    'Noto Sans',
    'Noto Sans Symbols',
    'Noto Color Emoji',
    'Segoe UI Emoji',
    'Arial Unicode MS',
  ];

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: Color(0xFF1C2DFF),
      onSecondary: Colors.white,
      error: Color(0xFFCF2E2E),
      onError: Colors.white,
      surface: Color(0xFFFFFFFF),
      onSurface: Color(0xFF16181D),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF6F6F9),
    );

    return _apply(base, isDark: false);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF3D5AFF),
      onPrimary: Colors.white,
      secondary: Color(0xFF91A0FF),
      onSecondary: Color(0xFF05070D),
      error: Color(0xFFFF6F6F),
      onError: Color(0xFF16090A),
      surface: Color(0xFF181C23),
      onSurface: Color(0xFFF2F3F5),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0E1116),
    );

    return _apply(base, isDark: true);
  }

  static ThemeData _apply(ThemeData base, {required bool isDark}) {
    final textTheme = _withFontFallback(
      GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.poppins(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        headlineSmall: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.sora(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: base.colorScheme.onSurface,
        ),
        titleMedium: GoogleFonts.sora(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
        titleSmall: GoogleFonts.sora(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          height: 1.45,
          color: base.colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          height: 1.45,
          color: base.colorScheme.onSurface.withValues(alpha: 0.86),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          height: 1.38,
          color: base.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: base.colorScheme.onSurface.withValues(alpha: 0.78),
        ),
      ),
    );

    final surfaceColor = isDark ? const Color(0xFF181C23) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2A303C)
        : const Color(0xFFE7E7EC);
    final navBackground = isDark
        ? const Color(0xFF0A0D14)
        : const Color(0xFFFFFFFF);

    return base.copyWith(
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _OmnyaPageTransitionsBuilder(),
          TargetPlatform.iOS: _OmnyaPageTransitionsBuilder(),
          TargetPlatform.macOS: _OmnyaPageTransitionsBuilder(),
          TargetPlatform.windows: _OmnyaPageTransitionsBuilder(),
          TargetPlatform.linux: _OmnyaPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF12151F) : Colors.white,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: brandBlue.withValues(alpha: isDark ? 0.28 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: cardBorder),
        ),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        height: 72,
        indicatorColor: brandBlueSoft.withValues(alpha: isDark ? 0.18 : 0.62),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 10.2,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? base.colorScheme.onSurface
                : base.colorScheme.onSurface.withValues(alpha: 0.68),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 21,
            color: selected
                ? brandBlueGlow
                : base.colorScheme.onSurface.withValues(alpha: 0.7),
          );
        }),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: brandBlue.withValues(alpha: isDark ? 0.28 : 0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        labelColor: base.colorScheme.onSurface,
        unselectedLabelColor: base.colorScheme.onSurface.withValues(
          alpha: 0.62,
        ),
        labelStyle: GoogleFonts.sora(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandBlue,
        foregroundColor: Colors.white,
        elevation: 8,
        extendedTextStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF141925) : const Color(0xFFF9FAFE),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brandBlueGlow, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: cardBorder, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: base.colorScheme.onSurface,
          side: BorderSide(color: cardBorder),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return isDark ? const Color(0xFFB8C0FF) : const Color(0xFF3C4560);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return brandBlue;
          }
          return isDark ? const Color(0xFF26304A) : const Color(0xFFD7DDF0);
        }),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cardBorder),
        ),
        textStyle: textTheme.bodyMedium,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: cardBorder),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: base.colorScheme.onSurface,
        textColor: base.colorScheme.onSurface,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return brandBlue.withValues(alpha: isDark ? 0.24 : 0.12);
            }
            return isDark ? const Color(0xFF111724) : Colors.white;
          }),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF121622)
            : const Color(0xFF161925),
        contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static TextTheme _withFontFallback(TextTheme theme) {
    TextStyle? apply(TextStyle? style) {
      return style?.copyWith(fontFamilyFallback: _fontFallback);
    }

    return theme.copyWith(
      displayLarge: apply(theme.displayLarge),
      displayMedium: apply(theme.displayMedium),
      displaySmall: apply(theme.displaySmall),
      headlineLarge: apply(theme.headlineLarge),
      headlineMedium: apply(theme.headlineMedium),
      headlineSmall: apply(theme.headlineSmall),
      titleLarge: apply(theme.titleLarge),
      titleMedium: apply(theme.titleMedium),
      titleSmall: apply(theme.titleSmall),
      bodyLarge: apply(theme.bodyLarge),
      bodyMedium: apply(theme.bodyMedium),
      bodySmall: apply(theme.bodySmall),
      labelLarge: apply(theme.labelLarge),
      labelMedium: apply(theme.labelMedium),
      labelSmall: apply(theme.labelSmall),
    );
  }
}

class _OmnyaPageTransitionsBuilder extends PageTransitionsBuilder {
  const _OmnyaPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
