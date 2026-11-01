import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adherent/adherent_action.dart'; // une action = nom + icône

/// Tableau de bord de l'ADHÉRENT.
/// Il affiche : une carte de bienvenue + une grille avec toutes les actions
/// possibles. Un appui sur une carte ouvre la page correspondante du shell.
class AdherentDashboardScreen extends StatelessWidget {
  const AdherentDashboardScreen({
    super.key,
    required this.profile,
    required this.items,
    required this.onOpen,
  });

  // Le profil de l'adhérent (sert à afficher son prénom)
  final UserProfile? profile;

  // La liste de toutes les actions (c'est AdherentShell qui la donne,
  // c'est la même liste que celle du menu latéral)
  final List<AdherentAction> items;

  // Fonction donnée par le shell : "ouvre la page numéro index".
  // On l'appelle quand l'utilisateur appuie sur une carte.
  final void Function(int index) onOpen;

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView : la page peut défiler si l'écran est petit
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- Carte de bienvenue verte -----
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
                // Logo de l'application
                const Icon(AppConfig.logoIcon,
                    size: 32, color: AppColors.primaryDark),
                const SizedBox(height: 12),
                // Prénom lu dans Firestore ('' si le profil est vide)
                Text(
                  'Bonjour ${profile?.prenom ?? ''} !',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark),
                ),
                const Text(
                  "Que souhaitez-vous faire aujourd'hui ?",
                  style:
                  TextStyle(fontSize: 16, color: AppColors.primaryDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ----- Grille de 2 colonnes avec toutes les actions -----
          GridView.count(
            crossAxisCount: 2, // 2 cartes par ligne
            crossAxisSpacing: 12, // espace horizontal entre les cartes
            mainAxisSpacing: 12, // espace vertical entre les cartes
            childAspectRatio: 1.15, // forme des cartes (largeur / hauteur)
            shrinkWrap: true, // la grille prend juste la place nécessaire
            // On désactive le défilement de la grille : c'est la page
            // entière (SingleChildScrollView) qui défile.
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // On commence à i = 1 : l'élément 0 est le tableau de bord
              // lui-même, inutile d'avoir une carte pour la page où on est.
              // Quand on appuie sur la carte, on dit au shell d'ouvrir la page i.
              for (var i = 1; i < items.length; i++)
                _carte(items[i], () => onOpen(i)),
            ],
          ),
        ],
      ),
    );
  }

  // Une carte blanche cliquable : icône verte + titre
  Widget _carte(AdherentAction action, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      // Bords arrondis + fine bordure grise
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      // InkWell : rend la carte cliquable (avec l'effet d'ondulation)
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, size: 32, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(
                action.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}