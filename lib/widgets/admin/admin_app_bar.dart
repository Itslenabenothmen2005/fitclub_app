import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Barre du haut verte, comme l'en-tête de Login (même identité visuelle).
PreferredSizeWidget adminAppBar(String title) {
  return AppBar(
    title: Text(title),
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.primaryDark,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppColors.primaryDark,
    ),
  );
}