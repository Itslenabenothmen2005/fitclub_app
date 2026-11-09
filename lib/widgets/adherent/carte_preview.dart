import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Carte bancaire visuelle : se remplit pendant la saisie.
class CartePreview extends StatelessWidget {
  const CartePreview({
    super.key,
    required this.numero, // ce qui est tapé dans le champ "numéro"
    required this.expiration, // ce qui est tapé dans le champ "expiration"
    required this.nom, // le nom du titulaire
  });

  final String numero;
  final String expiration;
  final String nom;

  @override
  Widget build(BuildContext context) {
    final chiffres = numero.replaceAll(' ', '');
    // On complète avec des • pour toujours afficher 16 positions.
    final masque = chiffres.padRight(16, '•');
    final numeroAffiche = [
      for (var i = 0; i < 16; i += 4) masque.substring(i, i + 4),
    ].join('  ');
    final expirationAffichee = expiration.isEmpty ? 'MM/AA' : expiration;

    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FITCLUB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              Icon(Icons.contactless_outlined, color: Colors.white),
            ],
          ),
          const Spacer(),
          Text(
            numeroAffiche,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  nom.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              Text(
                expirationAffichee,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}