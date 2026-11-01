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

  /// Crée le profil dans Firestore.
  /// Le paramètre "role" vient maintenant de l'écran d'inscription.
  /// Par défaut = adhérent (utilisé par la connexion Google).
  Future<void> createAdherentProfile({
    required User user,
    required String prenom,
    required String nom,
    UserRole role = UserRole.adherent, // <-- NOUVEAU
  }) {
    return _db.collection(AppConfig.usersCollection).doc(user.uid).set({
      'uid': user.uid,
      'prenom': prenom,
      'nom': nom,
      'email': user.email ?? '',
      'role': role.name, //MODIFIÉ : "adherent" ou "coach" dans Firestore
      'actif': true,
      'dateInscription': FieldValue.serverTimestamp(),
    });
  }
  }
