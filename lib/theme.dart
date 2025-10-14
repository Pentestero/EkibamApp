import 'package:flutter/material.dart';

// Define a more modern and accessible color palette
class LightModeColors {
  static const Color primary = Color(0xFF007BFF); // Vibrant Blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFCCE5FF); // Lighter Blue
  static const Color onPrimaryContainer = Color(0xFF0056B3); // Darker Blue
  static const Color secondary = Color(0xFF28A745); // Soft Green
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF6C757D); // Neutral Grey
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFBA1A1A); // Standard Red
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color inversePrimary = Color(0xFF99CCFF); // Complementary for inverse
  static const Color shadow = Color(0xFF000000);
  static const Color surface = Color(0xFFF8F9FA); // Light Grey
  static const Color onSurface = Color(0xFF212529); // Dark Grey
  static const Color background = Color(0xFFFFFFFF); // Pure White background
  static const Color onBackground = Color(0xFF212529); // Dark Grey
}

class DarkModeColors {
  static const Color primary = Color(0xFF3399FF); // Slightly darker vibrant Blue
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF004085); // Darker Blue
  static const Color onPrimaryContainer = Color(0xFF99CCFF); // Lighter Blue
  static const Color secondary = Color(0xFF218838); // Complementary Dark Green
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color tertiary = Color(0xFF495057); // Darker Grey
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFFFB4AB); // Standard Red
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);
  static const Color inversePrimary = Color(0xFF0056B3); // Complementary for inverse
  static const Color shadow = Color(0xFF000000);
  static const Color surface = Color(0xFF212529); // Dark Grey
  static const Color onSurface = Color(0xFFF8F9FA); // Light Grey
  static const Color background = Color(0xFF121212); // Very Dark Grey background
  static const Color onBackground = Color(0xFFF8F9FA); // Light Grey
}

// Font sizes (can be adjusted if needed, keeping current for now)
class FontSizes {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0; // Adjusted for better hierarchy
  static const double headlineSmall = 24.0; // Adjusted for better hierarchy
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double labelLarge = 16.0;
  static const double labelMedium = 14.0;
  static const double labelSmall = 12.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: LightModeColors.primary,
    onPrimary: LightModeColors.onPrimary,
    primaryContainer: LightModeColors.primaryContainer,
    onPrimaryContainer: LightModeColors.onPrimaryContainer,
    secondary: LightModeColors.secondary,
    onSecondary: LightModeColors.onSecondary,
    tertiary: LightModeColors.tertiary,
    onTertiary: LightModeColors.onTertiary,
    error: LightModeColors.error,
    onError: LightModeColors.onError,
    errorContainer: LightModeColors.errorContainer,
    onErrorContainer: LightModeColors.onErrorContainer,
    inversePrimary: LightModeColors.inversePrimary,
    shadow: LightModeColors.shadow,
    surface: LightModeColors.surface,
    onSurface: LightModeColors.onSurface,
  ),
  brightness: Brightness.light,
  appBarTheme: AppBarTheme(
    backgroundColor: LightModeColors.primary, // Use primary color for AppBar
    foregroundColor: LightModeColors.onPrimary, // Use onPrimary for text/icons
    elevation: 4, // Add a subtle shadow
    centerTitle: true,
  ),
  cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: LightModeColors.primaryContainer.withOpacity(0.3),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightModeColors.primary,
      foregroundColor: LightModeColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: LightModeColors.primary,
      textStyle: const TextStyle(fontSize: 16),
    ),
  ),
  // Add more theme properties as needed
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: DarkModeColors.primary,
    onPrimary: DarkModeColors.onPrimary,
    primaryContainer: DarkModeColors.primaryContainer,
    onPrimaryContainer: DarkModeColors.onPrimaryContainer,
    secondary: DarkModeColors.secondary,
    onSecondary: DarkModeColors.onSecondary,
    tertiary: DarkModeColors.tertiary,
    onTertiary: DarkModeColors.onTertiary,
    error: DarkModeColors.error,
    onError: DarkModeColors.onError,
    errorContainer: DarkModeColors.errorContainer,
    onErrorContainer: DarkModeColors.onErrorContainer,
    inversePrimary: DarkModeColors.inversePrimary,
    shadow: DarkModeColors.shadow,
    surface: DarkModeColors.surface,
    onSurface: DarkModeColors.onSurface,
  ),
  brightness: Brightness.dark,
  appBarTheme: AppBarTheme(
    backgroundColor: DarkModeColors.primary, // Use primary color for AppBar
    foregroundColor: DarkModeColors.onPrimary, // Use onPrimary for text/icons
    elevation: 4, // Add a subtle shadow
    centerTitle: true,
  ),
  cardTheme: CardThemeData( // Changed from CardTheme to CardThemeData
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    filled: true,
    fillColor: DarkModeColors.primaryContainer.withOpacity(0.3),
    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DarkModeColors.primary,
      foregroundColor: DarkModeColors.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: DarkModeColors.primary,
      textStyle: const TextStyle(fontSize: 16),
    ),
  ),
  // Add more theme properties as needed
);
