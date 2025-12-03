import 'package:flutter/material.dart';
import 'colors.dart';


class AppTypography {
// NOTE: Ensure you add the ITC Avant Garde font to pubspec.yaml and assets.
static const String fontFamily = 'ItcAvantGardeStdMd';


static TextTheme darkTextTheme = const TextTheme(
displayLarge: TextStyle(fontFamily: fontFamily, color: AppColors.white),
headlineMedium: TextStyle(fontFamily: fontFamily, color: AppColors.white),
bodyMedium: TextStyle(fontFamily: fontFamily, color: AppColors.textGrey),
bodySmall: TextStyle(fontFamily: fontFamily, color: AppColors.textGrey),
);
}