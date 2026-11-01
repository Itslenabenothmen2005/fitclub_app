import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class IconAvatar extends StatelessWidget {
  const IconAvatar({super.key, required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.primary.withValues(alpha: 0.3),
        child: Icon(icon, color: AppColors.primaryDark),
      ),
    );
  }
}