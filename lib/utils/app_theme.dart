import 'package:flutter/material.dart';


class AppColors {
  // ---------- Brand Colors ----------
  static const Color primary = Color(0xFF1E3A8A);        // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B5BC4);    // Lighter blue
  static const Color primaryDark = Color(0xFF0F1E4D);     // Darker blue
  
  static const Color secondary = Color(0xFF10B981);       // Emerald Green
  static const Color accent = Color(0xFFF59E0B);          // Amber
  
  // ---------- Backgrounds ----------
  static const Color background = Color(0xFFF9FAFB);      // Off-white
  static const Color surface = Colors.white;              // Cards
  static const Color surfaceVariant = Color(0xFFF3F4F6);  // Slightly darker
  
  // ---------- Text ----------
  static const Color textPrimary = Color(0xFF111827);     // Nearly black
  static const Color textSecondary = Color(0xFF6B7280);   // Gray
  static const Color textHint = Color(0xFF9CA3AF);        // Lighter gray
  
  // ---------- Status ----------
  static const Color success = Color(0xFF10B981);         // Green
  static const Color warning = Color(0xFFF59E0B);         // Amber
  static const Color error = Color(0xFFEF4444);           // Red
  static const Color info = Color(0xFF3B82F6);            // Blue
  
  // ---------- Status Badge Backgrounds ----------
  static const Color waitingBg = Color(0xFFFFF7E6);       // Light amber
  static const Color servingBg = Color(0xFFE7F7EE);       // Light green
  static const Color servedBg = Color(0xFFE6EEFE);        // Light blue
  static const Color passedBg = Color(0xFFFEECEC);        // Light red
  
  // ---------- Shadows ----------
  static const Color shadowLight = Color(0x0F000000);     // 6% black
  static const Color shadowMedium = Color(0x1A000000);    // 10% black
  static const Color shadowHeavy = Color(0x29000000);     // 16% black
}

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      
      // ---------- Scaffold Background ----------
      scaffoldBackgroundColor: AppColors.background,
      
      // ---------- AppBar ----------
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: AppColors.shadowHeavy,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      // ---------- Text ----------
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelLarge: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // ---------- Cards ----------
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 3,
        shadowColor: AppColors.shadowMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      
      // ---------- Elevated Buttons ----------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: AppColors.shadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // ---------- Outlined Buttons ----------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      
      // ---------- Text Buttons ----------
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      
      // ---------- Input Fields ----------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textHint),
      ),
      
      // ---------- Floating Action Button ----------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      
      // ---------- Snackbar ----------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // ---------- Divider ----------
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 24,
      ),
      
      // ---------- Switch ----------
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }
}