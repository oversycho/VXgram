import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tokens copied from the Figma Make design (index.css).
class VxColors {
  const VxColors({required this.bg, required this.surface, required this.surface2, required this.text, required this.muted,
      required this.border, required this.primary, required this.onPrimary, required this.pink, required this.error, required this.success});
  final Color bg, surface, surface2, text, muted, border, primary, onPrimary, pink, error, success;

  static const light = VxColors(bg: Color(0xFFFFFFFF), surface: Color(0xFFF4F4F8), surface2: Color(0xFFFFFFFF), text: Color(0xFF111118),
      muted: Color(0xFF8A8A99), border: Color(0xFFE4E4EC), primary: Color(0xFF6C5CE7), onPrimary: Color(0xFFFFFFFF),
      pink: Color(0xFFFF4D8D), error: Color(0xFFE5484D), success: Color(0xFF30A46C));
  static const dark = VxColors(bg: Color(0xFF0E0E12), surface: Color(0xFF1A1A22), surface2: Color(0xFF22222C), text: Color(0xFFF5F5FA),
      muted: Color(0xFF9A9AAB), border: Color(0xFF2A2A35), primary: Color(0xFF8B7DFF), onPrimary: Color(0xFF0E0E12),
      pink: Color(0xFFFF6BA1), error: Color(0xFFFF6369), success: Color(0xFF3DD68C));

  static VxColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;
  LinearGradient get brand => LinearGradient(colors: [primary, pink], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

class AppTheme {
  static ThemeData build(Brightness b, Locale locale) {
    final c = b == Brightness.dark ? VxColors.dark : VxColors.light;
    final base = ThemeData(brightness: b, useMaterial3: true).textTheme;
    final font = locale.languageCode == 'fa' ? GoogleFonts.vazirmatnTextTheme(base) : GoogleFonts.interTextTheme(base);
    final tt = font.apply(bodyColor: c.text, displayColor: c.text);
    OutlineInputBorder border(Color color, [double w = 0]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: w == 0 ? BorderSide.none : BorderSide(color: color, width: w));
    return ThemeData(
      brightness: b,
      useMaterial3: true,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: tt,
      colorScheme: ColorScheme(brightness: b, primary: c.primary, onPrimary: c.onPrimary, secondary: c.pink, onSecondary: Colors.white,
          error: c.error, onError: Colors.white, surface: c.bg, onSurface: c.text),
      appBarTheme: AppBarTheme(backgroundColor: c.bg, foregroundColor: c.text, elevation: 0, scrolledUnderElevation: 0, centerTitle: true),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: c.surface, labelStyle: TextStyle(color: c.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border(c.border), enabledBorder: border(c.border), focusedBorder: border(c.primary, 1.5), errorBorder: border(c.error, 1), focusedErrorBorder: border(c.error, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: c.primary, foregroundColor: c.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44), foregroundColor: c.text, side: BorderSide(color: c.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: c.surface2, showDragHandle: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
      dialogTheme: DialogThemeData(backgroundColor: c.surface2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: c.text, contentTextStyle: TextStyle(color: c.bg)),
      dividerTheme: DividerThemeData(color: c.border, space: 1, thickness: 1),
    );
  }
}
