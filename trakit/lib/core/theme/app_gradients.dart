import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.brand, AppColors.brandDeep],
  );

  static const LinearGradient sunrise = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.accent, AppColors.accentDeep],
  );

  static const LinearGradient hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF7C5CFF),
      Color(0xFFB084FF),
      Color(0xFFFF7A59),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient night = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0E29), Color(0xFF0B0613)],
  );

  static const LinearGradient glass = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x33FFFFFF), Color(0x0AFFFFFF)],
  );

  static const LinearGradient glassLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1ECFF)],
  );

  // Category gradients keyed by name (string) for cheap lookup.
  static const Map<String, LinearGradient> category = {
    'Food': LinearGradient(
      colors: [AppColors.foodA, AppColors.foodB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Groceries': LinearGradient(
      colors: [AppColors.groceriesA, AppColors.groceriesB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Entertainment': LinearGradient(
      colors: [AppColors.entertainmentA, AppColors.entertainmentB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Travel': LinearGradient(
      colors: [AppColors.travelA, AppColors.travelB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Shopping': LinearGradient(
      colors: [AppColors.shoppingA, AppColors.shoppingB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Bills': LinearGradient(
      colors: [AppColors.billsA, AppColors.billsB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Health': LinearGradient(
      colors: [AppColors.healthA, AppColors.healthB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Subscriptions': LinearGradient(
      colors: [AppColors.subscriptionsA, AppColors.subscriptionsB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'Banking': LinearGradient(
      colors: [AppColors.bankingA, AppColors.bankingB],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };
}
