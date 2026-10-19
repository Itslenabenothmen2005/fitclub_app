import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'admin/admin_shell.dart';
import 'auth/login_screen.dart';

/// AuthGate = "le portier" de l'application.
/// Il décide quel écran afficher selon l'utilisateur connecté :
///  - personne de connecté  -> écran de connexion
///  - connecté en admin     -> espace administrateur
///  - connecté autre rôle   -> message "bientôt disponible"
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder : se redessine tout seul quand la connexion change
    // (connexion ou déconnexion), sans qu'on ait rien à rafraîchir.
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges, // "qui est connecté ?"
      builder: (context, authSnapshot) {
        // Firebase n'a pas encore répondu : roue de chargement.
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnapshot.data;

        // Personne n'est connecté : on affiche la connexion.
        if (user == null) return const LoginScreen();

        // Quelqu'un est connecté : on lit son profil dans Firestore
        // pour connaître son rôle (adherent, coach ou admin).
        return StreamBuilder<UserProfile?>(
          stream: UserService().watchProfile(user.uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final role = profileSnapshot.data?.role;

            // Administrateur : on ouvre son espace.
            if (role == UserRole.admin) return const AdminShell();

            // Adhérent ou coach : leurs espaces ne sont pas encore faits.
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Votre espace sera bientôt disponible.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => AuthService().signOut(),
                        child: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}