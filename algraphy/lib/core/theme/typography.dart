import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Define the base style
  static final TextStyle _baseStyle = GoogleFonts.inter();
  static String? get fontFamily => GoogleFonts.inter().fontFamily;

  static TextTheme get textTheme => GoogleFonts.interTextTheme().copyWith(
    displayLarge: _baseStyle.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    titleLarge: _baseStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    bodyLarge: _baseStyle.copyWith(fontSize: 16, fontWeight: FontWeight.normal),
    bodyMedium: _baseStyle.copyWith(fontSize: 14, fontWeight: FontWeight.normal),
    labelSmall: _baseStyle.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
  );
}