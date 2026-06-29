import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Nature-inspired palette — forest greens, moss, sage, and warm cream.
class NatureColors {
  NatureColors._();

  static const forest = Color(0xFF1A5D3A);
  static const forestDark = Color(0xFF0F3D26);
  static const moss = Color(0xFF2D8B57);
  static const leaf = Color(0xFF4CAF72);
  static const sage = Color(0xFF8FBC8F);
  static const mint = Color(0xFFE8F5E9);
  static const cream = Color(0xFFF7FBF8);
  static const bark = Color(0xFF3E4A3A);
  static const soil = Color(0xFF6B7B6B);
  static const skyMist = Color(0xFFD4EAD9);
  static const sunGlow = Color(0xFFAAC896);

  static const gradientMain = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, moss, leaf],
  );

  static const gradientSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cream, mint],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A5D3A), Color(0xFF2D7A4E), Color(0xFF3D9A62)],
  );
}

class AppTheme {
  static ThemeData light() {
    final textTheme = GoogleFonts.nunitoTextTheme();
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: NatureColors.forest,
        primary: NatureColors.forest,
        secondary: NatureColors.moss,
        surface: NatureColors.cream,
        onPrimary: Colors.white,
      ),
      scaffoldBackgroundColor: NatureColors.cream,
      textTheme: textTheme.apply(bodyColor: NatureColors.bark, displayColor: NatureColors.forestDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.nunito(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: NatureColors.soil),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: NatureColors.skyMist),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: NatureColors.moss, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NatureColors.forest,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: NatureColors.forest.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: NatureColors.moss,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: NatureColors.skyMist.withValues(alpha: 0.8)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: NatureColors.moss,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NatureColors.forestDark,
        contentTextStyle: GoogleFonts.nunito(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
