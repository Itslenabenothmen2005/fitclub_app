import 'package:flutter/material.dart';

/// Une action de l'adhérent : un nom + une icône.
/// (Utilisée par le menu du shell ET par les cartes du tableau de bord.)
class AdherentAction {
  const AdherentAction(this.label, this.icon);
  final String label;
  final IconData icon;
}