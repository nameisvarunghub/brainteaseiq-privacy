import 'package:flutter/material.dart';

/// TrakIt's brand palette.
///
/// We avoid corporate blue. Our identity is plum night-sky + warm sunrise
/// accents + vivid category swatches. Pure black is reserved for OLED bleed
/// outs; everything visible is a deep tinted near-black so gradients sing.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFFB084FF); // soft violet
  static const Color brandDeep = Color(0xFF7C5CFF);
  static const Color brandGlow = Color(0xFFE0CCFF);
  static const Color accent = Color(0xFFFFB37C); // peach sunrise
  static const Color accentDeep = Color(0xFFFF7A59);

  // Surfaces — dark by default
  static const Color bg = Color(0xFF0B0613);
  static const Color bgElevated = Color(0xFF14091F);
  static const Color surface = Color(0xFF1A0E29);
  static const Color surfaceHigh = Color(0xFF221334);
  static const Color stroke = Color(0x33FFFFFF);
  static const Color strokeSoft = Color(0x14FFFFFF);

  // Light variants
  static const Color bgLight = Color(0xFFF6F3FF);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightAlt = Color(0xFFEEE8FB);
  static const Color strokeLight = Color(0x14000000);

  // Text
  static const Color textPrimary = Color(0xFFFDFAFF);
  static const Color textSecondary = Color(0xCCFDFAFF);
  static const Color textMuted = Color(0x99FDFAFF);
  static const Color textPrimaryLight = Color(0xFF120821);
  static const Color textSecondaryLight = Color(0xFF4A3A66);
  static const Color textMutedLight = Color(0xFF7A6E94);

  // Semantic
  static const Color success = Color(0xFF6BE3B0);
  static const Color warn = Color(0xFFFFC774);
  static const Color danger = Color(0xFFFF7494);
  static const Color info = Color(0xFF7CC8FF);

  // Category swatches (each: vivid pair for gradient pills)
  static const Color foodA = Color(0xFFFF8A65);
  static const Color foodB = Color(0xFFFF5E7E);
  static const Color groceriesA = Color(0xFF7BE495);
  static const Color groceriesB = Color(0xFF36C998);
  static const Color entertainmentA = Color(0xFFB084FF);
  static const Color entertainmentB = Color(0xFF7C5CFF);
  static const Color travelA = Color(0xFF7CC8FF);
  static const Color travelB = Color(0xFF5C8CFF);
  static const Color shoppingA = Color(0xFFFFB37C);
  static const Color shoppingB = Color(0xFFFF7A59);
  static const Color billsA = Color(0xFFFFD27C);
  static const Color billsB = Color(0xFFFFA64C);
  static const Color healthA = Color(0xFFFF94B8);
  static const Color healthB = Color(0xFFEA5A8A);
  static const Color subscriptionsA = Color(0xFF94EAFF);
  static const Color subscriptionsB = Color(0xFF5AC9EA);
  static const Color bankingA = Color(0xFFC0B0FF);
  static const Color bankingB = Color(0xFF8E7BFF);
}
