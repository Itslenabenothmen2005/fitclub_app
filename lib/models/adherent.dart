import 'package:cloud_firestore/cloud_firestore.dart'; // pour le type Timestamp
import 'package:flutter/material.dart';

enum StatutAbonnement {
  actif('Abonnement actif', Icons.check_circle_outline),
  expire('Abonnement expiré', Icons.error_outline),
  aucun('Sans abonnement', Icons.remove_circle_outline);

  const StatutAbonnement(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Adherent {
  final String id;
  final String prenom;
  final String nom;
  final String email;
  final String telephone;
  final DateTime dateInscription;
  final String? abonnementId;
  final int? dureeAbonnementMois;
  final DateTime? dateDebutAbonnement;
  final bool actif;

  const Adherent({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.dateInscription,
    required this.abonnementId,
    required this.dateDebutAbonnement,
    required this.actif,
    this.dureeAbonnementMois,
  });

  String get nomComplet => '$prenom $nom';

  Adherent withActif(bool value) => Adherent(
    id: id,
    prenom: prenom,
    nom: nom,
    email: email,
    telephone: telephone,
    dateInscription: dateInscription,
    abonnementId: abonnementId,
    dureeAbonnementMois: dureeAbonnementMois,
    dateDebutAbonnement: dateDebutAbonnement,
    actif: value,
  );


  //transformer une fiche Firestore en objet Adherent

  factory Adherent.fromMap(String id, Map<String, dynamic> d) => Adherent(
    id: id,
    prenom: d['prenom'] as String? ?? '',
    nom: d['nom'] as String? ?? '',
    email: d['email'] as String? ?? '',
    telephone: d['telephone'] as String? ?? '',
    dateInscription:
    (d['dateInscription'] as Timestamp?)?.toDate() ?? DateTime.now(),
    // Ces deux champs peuvent être absents (adhérent sans abonnement) : null.
    abonnementId: d['abonnementId'] as String?,
    dureeAbonnementMois:
        (d['dureeAbonnementMois'] as num?)?.toInt(),
    dateDebutAbonnement:
    (d['dateDebutAbonnement'] as Timestamp?)?.toDate(),
    actif: d['actif'] as bool? ?? true,
  );

  /// Objet Adherent -> données à enregistrer dans Firestore.
  Map<String, dynamic> toMap() => {
    'prenom': prenom,
    'nom': nom,
    'email': email,
    'telephone': telephone,
    'dateInscription': Timestamp.fromDate(dateInscription),
    'abonnementId': abonnementId,
    'dureeAbonnementMois': dureeAbonnementMois,
    'dateDebutAbonnement': dateDebutAbonnement == null
        ? null
        : Timestamp.fromDate(dateDebutAbonnement!),
    'actif': actif,
  };
}