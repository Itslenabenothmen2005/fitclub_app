import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../models/user_profile.dart';

class UserService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Écoute le profil en temps réel (null si le document n'existe pas).
  Stream<UserProfile?> watchProfile(String uid) {
    return _db.collection(AppConfig.usersCollection).doc(uid).snapshots().map(
          (snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return UserProfile.fromMap(snap.id, data);
      },
    );
  }

  /// Inscription publique : le rôle est TOUJOURS adhérent.
  /// Aucun mot de passe n'est stocké ici (Firebase Auth s'en charge).
  Future<void> createAdherentProfile({
    required User user,
    required String prenom,
    required String nom,
  }) {
    return _db.collection(AppConfig.usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'prenom': prenom,
      'nom': nom,
      'email': user.email ?? '',
      'role': UserRole.adherent.name,
      'actif': true,
      'dateInscription': FieldValue.serverTimestamp(),
    });
  }
}