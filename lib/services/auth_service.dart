import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/user_profile.dart'; // NOUVEAU : pour UserRole
import 'user_service.dart';

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService({UserService? userService})
      : _userService = userService ?? UserService();

  final UserService _userService;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  //authStateChanges est un flux qui indique si quelqu'un est connecté ou non.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Renvoie true si la connexion a réellement réussi.
  Future<bool> signIn({required String email, required String password}) {
    return _guard(() async {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      return true;
    });
  }

  Future<bool> signUp({
    required String prenom,
    required String nom,
    required String email,
    required String password,
    required UserRole role, // NOUVEAU : le rôle choisi à l'inscription
  }) {
    return _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = cred.user!;
      await user.updateDisplayName('$prenom $nom');
      await _userService.createAdherentProfile(
        user: user,
        prenom: prenom.trim(),
        nom: nom.trim(),
        role: role, // NOUVEAU : on enregistre le rôle choisi
      );
      return true;
    });
  }

  /// true = connecté, false = l'utilisateur a fermé la fenêtre Google.
  Future<bool> signInWithGoogle({
    UserRole role = UserRole.adherent, // NOUVEAU : adhérent par défaut
  }) {
    return _guard(() async {
      final provider = GoogleAuthProvider()..addScope('email');
      try {
        final cred = kIsWeb
            ? await _auth.signInWithPopup(provider) //signInWithPopup sur le web
            : await _auth.signInWithProvider(provider); //signInWithProvider sur mobile

        // Le rôle est enregistré seulement à la toute première connexion.
        if (cred.additionalUserInfo?.isNewUser ?? false) {
          final user = cred.user!;
          final parts = (user.displayName ?? '').trim().split(' ');
          final prenom = parts.first;
          final nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          await _userService.createAdherentProfile(
            user: user,
            prenom: prenom,
            nom: nom,
            role: role, // NOUVEAU
          );
        }
        return true;
      } on FirebaseAuthException catch (e) {
        const cancelled = {
          'canceled',
          'cancelled-popup-request',
          'popup-closed-by-user',
          'web-context-canceled',
        };
        if (cancelled.contains(e.code)) return false;
        rethrow;
      }
    });
  }

  //sendPasswordReset envoie l'e-mail de réinitialisation
  Future<void> sendPasswordReset(String email) {
    return _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _auth.signOut();

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (Firebase.apps.isEmpty) {
      throw const AuthFailure(
          "Firebase n'est pas encore configuré. Suivez les étapes de "
              "configuration puis relancez l'application.");
    }
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    } on FirebaseException catch (e) {
      throw AuthFailure(
          "Erreur d'accès aux données (${e.code}). Veuillez réessayer.");
    }
  }

  //_messageFor traduit les codes d'erreur en phrases françaises
  String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return "L'adresse e-mail n'est pas valide.";
      case 'user-disabled':
        return 'Ce compte a été désactivé. Contactez la salle de sport.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential': // même message, pour ne pas révéler si l'e-mail existe
        return 'E-mail ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cette adresse e-mail.';
      case 'weak-password':
        return 'Mot de passe trop faible. Choisissez-en un plus long.';
      case 'network-request-failed':
        return 'Pas de connexion Internet. Vérifiez votre réseau et réessayez.';
      case 'too-many-requests':
        return 'Trop de tentatives. Patientez quelques minutes puis réessayez.';
      case 'account-exists-with-different-credential':
        return 'Un compte existe déjà avec cet e-mail via une autre méthode de connexion.';
      case 'operation-not-allowed':
        return "Ce mode de connexion n'est pas activé dans la console Firebase.";
      default:
        return 'Une erreur est survenue ($code). Veuillez réessayer.';
    }
  }
}