import 'package:flutter/material.dart';
import 'package:bladi_go_client/style/color.dart';

class AppTextStyles {
  // Headings
  static const TextStyle heading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
    letterSpacing: -0.5,
  );
  
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.darkText,
  );
  
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );
  
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
  );

  // Body text
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.mediumText,
    height: 1.5,
  );
  
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.darkText,
    height: 1.5,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.lightText,
    height: 1.5,
  );
  
  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Labels and captions
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumText,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColors.lightText,
  );
}