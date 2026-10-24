import 'package:flutter/material.dart';

abstract final class PawColors {
  static const ink = Color(0xFF092F43);
  static const petrol = Color(0xFF195B6B);
  static const petrolDark = Color(0xFF104858);
  static const ice = Color(0xFFE9F8FC);
  static const iceDeep = Color(0xFFC0E8F1);
  static const muted = Color(0xFF617D90);
  static const line = Color(0xFFD6EEF4);
  static const orange = Color(0xFFF58B00);
  static const orangeSoft = Color(0xFFFFF0D9);
  static const green = Color(0xFF2F8C43);
}

ThemeData pawshotsTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Manrope',
    colorScheme: ColorScheme.fromSeed(
      seedColor: PawColors.petrol,
      primary: PawColors.petrol,
      secondary: PawColors.iceDeep,
      surface: Colors.white,
      onSurface: PawColors.ink,
    ),
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: const BorderSide(color: PawColors.line),
  );
  return base.copyWith(
    scaffoldBackgroundColor: PawColors.ice,
    textTheme: base.textTheme
        .apply(bodyColor: PawColors.ink, displayColor: PawColors.ink)
        .copyWith(
          headlineLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 38,
            height: 1.16,
            fontWeight: FontWeight.w800,
            color: PawColors.ink,
            letterSpacing: -1.3,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: PawColors.ink,
            letterSpacing: -.8,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: PawColors.ink,
            letterSpacing: -.5,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: PawColors.ink,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            height: 1.5,
            color: PawColors.ink,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            height: 1.5,
            color: PawColors.muted,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PawColors.ice,
      foregroundColor: PawColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: PawColors.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: PawColors.petrol, width: 1.7),
      ),
      labelStyle: const TextStyle(color: PawColors.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        backgroundColor: PawColors.petrol,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        foregroundColor: PawColors.petrol,
        side: const BorderSide(color: PawColors.iceDeep),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PawColors.petrol,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: PawColors.ice,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerColor: PawColors.line,
    dividerTheme: const DividerThemeData(color: PawColors.line, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: PawColors.petrol,
    ),
  );
}
