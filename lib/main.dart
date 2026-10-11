import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'screens/admin/admin_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FitClubApp());
}

class FitClubApp extends StatelessWidget {
  const FitClubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // TEMPORAIRE : on ouvre directement l'espace Administrateur pour le
      // tester sans backend. Plus tard : home: const AuthGate() (Firebase).
      home: const AdminShell(),
    );
  }
}