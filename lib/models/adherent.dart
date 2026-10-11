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
        dateDebutAbonnement: dateDebutAbonnement,
        actif: value,
      );
}