import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Statut sémantique d'un médicament (péremption / stock).
enum MedStatus { ok, bientot, bas, rupture, perime }

class StatusStyle {
  final Color fg;
  final Color bg;
  final String label;
  final IconData icon;
  const StatusStyle({required this.fg, required this.bg, required this.label, required this.icon});
}

/// Design tokens — direction « Cocon » (crème, corail, sauge).
class CoconColors {
  static const bg = Color(0xFFFBF6EF);
  static const surface = Color(0xFFFFFFFF);
  static const sunk = Color(0xFFF4ECE1);
  static const ink = Color(0xFF3A352F);
  static const muted = Color(0xFF9A9087);
  static const line = Color(0xFFECE2D5);

  static const accent = Color(0xFFEC8A6A);
  static const accentSoft = Color(0xFFFCEAE1);

  static const sage = Color(0xFF6FA086);
  static const sageSoft = Color(0xFFE5EFE8);

  static const memberPalette = [
    Color(0xFFE8896B),
    Color(0xFF5B8C7B),
    Color(0xFFE0A94F),
    Color(0xFF9A7AA8),
    Color(0xFF5B8C9E),
    Color(0xFFD98A4E),
  ];

  static Color memberColor(int seed) => memberPalette[seed.abs() % memberPalette.length];

  static const Map<MedStatus, StatusStyle> status = {
    MedStatus.perime: StatusStyle(fg: Color(0xFFCE5A4E), bg: Color(0xFFFAE5E1), label: 'Périmé', icon: Icons.warning_amber_rounded),
    MedStatus.bientot: StatusStyle(fg: Color(0xFFC58A2E), bg: Color(0xFFFBEFD6), label: 'Périme bientôt', icon: Icons.schedule_rounded),
    MedStatus.bas: StatusStyle(fg: Color(0xFF8C6BA0), bg: Color(0xFFF0E8F3), label: 'Stock bas', icon: Icons.shopping_cart_outlined),
    MedStatus.rupture: StatusStyle(fg: Color(0xFF8C6BA0), bg: Color(0xFFF0E8F3), label: 'À racheter', icon: Icons.shopping_cart_outlined),
    MedStatus.ok: StatusStyle(fg: Color(0xFF5E9079), bg: Color(0xFFE5EFE8), label: 'En stock', icon: Icons.shield_outlined),
  };
}

/// Rayons partagés par les composants.
class CoconRadii {
  static const card = 22.0;
  static const tile = 16.0;
  static const pill = 999.0;
}

ThemeData buildCoconTheme() {
  final display = GoogleFonts.quicksandTextTheme();
  final body = GoogleFonts.nunitoTextTheme();

  final colorScheme = ColorScheme.fromSeed(
    seedColor: CoconColors.accent,
    brightness: Brightness.light,
    surface: CoconColors.surface,
    primary: CoconColors.accent,
    secondary: CoconColors.sage,
  );

  final textTheme = body.copyWith(
    displayLarge: display.displayLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    displayMedium: display.displayMedium?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    displaySmall: display.displaySmall?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    headlineLarge: display.headlineLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    headlineMedium: display.headlineMedium?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    headlineSmall: display.headlineSmall?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    titleLarge: display.titleLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700, letterSpacing: -0.4),
    titleMedium: display.titleMedium?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    titleSmall: display.titleSmall?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    bodyLarge: body.bodyLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w600),
    bodyMedium: body.bodyMedium?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w600),
    bodySmall: body.bodySmall?.copyWith(color: CoconColors.muted, fontWeight: FontWeight.w600),
    labelLarge: body.labelLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w800),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: CoconColors.bg,
    textTheme: textTheme,
    fontFamily: GoogleFonts.nunito().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: CoconColors.surface,
      foregroundColor: CoconColors.ink,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: display.titleLarge?.copyWith(color: CoconColors.ink, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      color: CoconColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CoconRadii.card),
        side: const BorderSide(color: CoconColors.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CoconColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoconRadii.pill),
        borderSide: const BorderSide(color: CoconColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoconRadii.pill),
        borderSide: const BorderSide(color: CoconColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CoconRadii.pill),
        borderSide: const BorderSide(color: CoconColors.accent, width: 1.5),
      ),
      hintStyle: const TextStyle(color: CoconColors.muted, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CoconColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CoconRadii.pill)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: CoconColors.ink,
        side: const BorderSide(color: CoconColors.line, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CoconRadii.pill)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CoconColors.surface,
      selectedColor: CoconColors.ink,
      side: const BorderSide(color: CoconColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CoconRadii.pill)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, color: CoconColors.muted, fontSize: 13.5),
      secondaryLabelStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 13.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: CoconColors.surface,
      indicatorColor: CoconColors.accentSoft,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11,
            color: states.contains(WidgetState.selected) ? CoconColors.accent : CoconColors.muted,
          )),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? CoconColors.accent : CoconColors.muted,
          )),
    ),
    dividerTheme: const DividerThemeData(color: CoconColors.line, thickness: 1, space: 1),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? CoconColors.sage : CoconColors.line,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
