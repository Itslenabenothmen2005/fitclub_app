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
  /// - Toujours : un document dans "users" (sert à la connexion et au rôle).
  /// - Si le rôle est "adhérent" : AUSSI une fiche dans "adherents"
  ///   (c'est ce que l'admin voit dans sa page Adhérents).
  Future<void> createAdherentProfile({
    required User user,
    required String prenom,
    required String nom,
    UserRole role = UserRole.adherent,
  }) {
    // Un batch = les deux écritures réussissent ensemble, ou aucune.
    final batch = _db.batch();

    // 1) Document "users" (comme avant)
    batch.set(_db.collection(AppConfig.usersCollection).doc(user.uid), {
      'uid': user.uid,
      'prenom': prenom,
      'nom': nom,
      'email': user.email ?? '',
      'role': role.name, // "adherent" ou "coach"
      'actif': true,
      'dateInscription': FieldValue.serverTimestamp(),
    });

    // 2) Fiche "adherents" : seulement pour les adhérents (pas les coachs).
    //    Mêmes champs que les fiches créées par l'admin.
    //    L'identifiant du document = l'uid du compte.
    if (role == UserRole.adherent) {
      batch.set(_db.collection('adherents').doc(user.uid), {
        'prenom': prenom,
        'nom': nom,
        'email': user.email ?? '',
        'telephone': '', // l'inscription ne demande pas le téléphone
        'actif': true,
        'dateInscription': FieldValue.serverTimestamp(),
        'abonnementId': null, // rempli au moment du paiement
        'dateDebutAbonnement': null, // rempli au moment du paiement
      });
    }

    return batch.commit();
  }
}