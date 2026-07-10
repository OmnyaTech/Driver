import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final class AppTheme {
  static const Color brandBlue = Color(0xFF0000CD);
  static const Color brandBlueGlow = Color(0xFF2E45FF);
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandGray = Color(0xFFD3D3D3);

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: brandBlue,
      onPrimary: Colors.white,
      secondary: Color(0xFF1C2DFF),
      onSecondary: Colors.white,
      error: Color(0xFFCF2E2E),
      onError: Colors.white,
      surface: Color(0xFFF5F7FB),
      onSurface: Color(0xFF10131A),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F7FB),
    );

    return _apply(base, isDark: false);
  }

  static ThemeData dark() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF4E63FF),
      onPrimary: Colors.white,
      secondary: Color(0xFF91A0FF),
      onSecondary: Color(0xFF05070D),
      error: Color(0xFFFF6F6F),
      onError: Color(0xFF16090A),
      surface: Color(0xFF090B12),
      onSurface: Color(0xFFF4F7FF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF060811),
    );

    return _apply(base, isDark: true);
  }

  static ThemeData _apply(ThemeData base, {required bool isDark}) {
    final textTheme = GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
      headlineMedium: GoogleFonts.poppins(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: base.colorScheme.onSurface,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: base.colorScheme.onSurface,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: base.colorScheme.onSurface,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 15,
        height: 1.45,
        color: base.colorScheme.onSurface,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 13,
        height: 1.45,
        color: base.colorScheme.onSurface.withValues(alpha: 0.86),
      ),
      labelLarge: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: base.colorScheme.onSurface.withValues(alpha: 0.78),
      ),
    );

    final surfaceColor = isDark ? const Color(0xFF121622) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF232A3D)
        : const Color(0xFFE3E8F5);
    final navBackground = isDark
        ? const Color(0xFF121521)
        : const Color(0xFFFDFEFF);

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF11131D) : Colors.white,
        foregroundColor: base.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        shadowColor: brandBlue.withValues(alpha: isDark ? 0.28 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cardBorder),
        ),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        height: 82,
        indicatorColor: brandBlue.withValues(alpha: isDark ? 0.28 : 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? base.colorScheme.onSurface
                : base.colorScheme.onSurface.withValues(alpha: 0.68),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
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
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF111724) : const Color(0xFFF8FAFF),
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: base.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandBlueGlow, width: 1.6),
        ),
      ),
      dividerTheme: DividerThemeData(color: cardBorder, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
            borderRadius: BorderRadius.circular(18),
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
          borderRadius: BorderRadius.circular(18),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
    );
  }
}
