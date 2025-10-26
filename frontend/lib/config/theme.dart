import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary Green Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color accentGreen = Color(0xFF66BB6A);
  
  // Secondary Colors
  static const Color secondaryBlue = Color(0xFF1976D2);
  static const Color accentOrange = Color(0xFFFF9800);
  static const Color accentRed = Color(0xFFE53935);
  
  // Neutral Colors - IMPROVED CONTRAST
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color grey = Color(0xFF757575); // Darker for better contrast
  static const Color darkGrey = Color(0xFF424242);
  static const Color black = Color(0xFF212121);
  
  // Text Colors - NEW for better readability
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: lightGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: lightGreen,
        surface: white,
        error: error,
        onPrimary: textOnPrimary,
        onSurface: textPrimary,
      ),
      
      // Text Theme - IMPROVED with better contrast
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        // Slightly increased sizes for better readability across devices
        displayLarge: GoogleFonts.roboto(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.roboto(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.15,
        ),
        displaySmall: GoogleFonts.roboto(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.25,
        ),
        headlineMedium: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.25,
        ),
        titleLarge: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          height: 1.35,
        ),
        titleMedium: GoogleFonts.roboto(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.35,
        ),
        bodyLarge: GoogleFonts.roboto(
          fontSize: 17,
          color: textPrimary,
          height: 1.55,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 15,
          color: textSecondary,
          height: 1.55,
        ),
        bodySmall: GoogleFonts.roboto(
          fontSize: 13,
          color: textSecondary,
          height: 1.55,
        ),
        labelLarge: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          height: 1.35,
        ),
      ),
      
      // AppBar Theme - IMPROVED text contrast
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: white,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(
          color: white,
          size: 24,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
  shadowColor: black.withValues(alpha: 26),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Elevated Button Theme - Better text contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration Theme - IMPROVED label and hint contrast
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: grey.withValues(alpha: 128)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: grey.withValues(alpha: 128)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        labelStyle: GoogleFonts.roboto(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: GoogleFonts.roboto(
          color: textHint,
          fontSize: 14,
        ),
        floatingLabelStyle: GoogleFonts.roboto(
          color: primaryGreen,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      
      // List Tile Theme - Better text colors
      listTileTheme: ListTileThemeData(
        tileColor: white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: textSecondary,
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: primaryGreen,
        size: 24,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryGreen,
        foregroundColor: white,
        elevation: 4,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
  color: grey.withValues(alpha: 77),
        thickness: 1,
        space: 1,
      ),

      // Chip Theme - Better contrast
      chipTheme: ChipThemeData(
  backgroundColor: grey.withValues(alpha: 26),
        selectedColor: primaryGreen,
  disabledColor: grey.withValues(alpha: 77),
        labelStyle: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        secondaryLabelStyle: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// Gradient Decorations - IMPROVED with better text contrast on gradients
class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppTheme.primaryGreen,
      AppTheme.lightGreen,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [
      Color(0xFFF1F8F4), // Lighter for better text readability
      Color(0xFFE8F5E9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // NEW: Gradients with guaranteed text readability
  static const LinearGradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF1B5E20),
      Color(0xFF2E7D32),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// Box Shadows - Softer for modern look
class AppShadows {
  static List<BoxShadow> cardShadow = [
    BoxShadow(
  color: Colors.black.withValues(alpha: 20),
      blurRadius: 12,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  // Lighter shadow for modern, subtle elevation
  static List<BoxShadow> cardShadowLight = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 12),
      blurRadius: 6,
      offset: const Offset(0, 2),
      spreadRadius: 0,
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
  color: AppTheme.primaryGreen.withValues(alpha: 64),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
  color: Colors.black.withValues(alpha: 31),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];
}

// Helper extension for text contrast
extension ColorContrastExtension on Color {
  /// Returns white or black depending on which provides better contrast
  Color get contrastText {
    final luminance = computeLuminance();
    return luminance > 0.5 ? AppTheme.black : AppTheme.white;
  }

  /// Small helper to mimic the project's previous `withValues(alpha: ..)` usage.
  /// Accepts either an `alpha` (0-255) or `opacity` (0.0-1.0). If both are
  /// provided, `alpha` takes precedence.
  Color withValues({int? alpha, double? opacity}) {
    if (alpha != null) return withAlpha(alpha);
    if (opacity != null) {
      // Avoid using [withOpacity] (deprecated in this codebase). Convert
      // opacity (0.0-1.0) to alpha (0-255) for precise control.
      int a = (opacity * 255).round();
      if (a < 0) a = 0;
      if (a > 255) a = 255;
      return withAlpha(a);
    }
    return this;
  }
}