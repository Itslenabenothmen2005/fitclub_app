import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

/// Dashboard du COACH (page d'accueil simple, à compléter ensuite).
class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({super.key, required this.profile});

  // Le profil vient de Firestore (donné par AuthGate)
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Même barre verte que l'espace admin
      appBar: AppBar(
        title: const Text('Espace Coach'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        actions: [
          // Bouton de déconnexion : AuthGate revient seul à la connexion
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(AppConfig.logoIcon,
                      size: 32, color: AppColors.primaryDark),
                  const SizedBox(height: 12),
                  Text(
                    'Bonjour Coach ${profile?.prenom ?? ''} !',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark),
                  ),
                  const Text(
                    'Bienvenue dans votre espace coach.',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Raccourcis (pour l'instant ce sont juste des cartes)
            _card(Icons.event_note_outlined, 'Mes séances'),
            const SizedBox(height: 12),
            _card(Icons.people_outline, 'Mes adhérents'),
          ],
        ),
      ),
    );
  }

  // Petite carte blanche avec une icône et un titre
  Widget _card(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}