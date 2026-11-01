import 'package:flutter/material.dart';

import '../admin/empty_state.dart';

/// Page provisoire pour les fonctionnalités pas encore faites.
/// On supprimera ce fichier quand tout sera terminé.
class BientotDisponible extends StatelessWidget {
  const BientotDisponible(this.titre, {super.key});

  final String titre;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.construction_outlined,
      message: '$titre : bientôt disponible',
    );
  }
}