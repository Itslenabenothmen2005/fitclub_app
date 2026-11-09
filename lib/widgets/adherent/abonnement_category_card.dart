import 'package:flutter/material.dart';

import '../../models/abonnement.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Carte d'une CATÉGORIE d'abonnement (natation, yoga...) :
/// image, description, formules (une ligne par durée avec un bouton
/// Souscrire) et horaires.
/// Ce fichier contient aussi ses petits morceaux :
///   - _FormuleRow          : une ligne de prix
///   - _AbonnementImage     : l'image de l'abonnement
///   - showAbonnementDetails: la fenêtre "détails" (icône œil)
class AbonnementCategoryCard extends StatelessWidget {
  const AbonnementCategoryCard({
    super.key,
    required this.abonnement,
    required this.coachDe, // donne le nom du coach d'un horaire
    required this.onSouscrire, // appui sur "Souscrire" d'une formule
    required this.onDetails, // appui sur l'icône œil
  });

  final Abonnement abonnement;
  final String? Function(HoraireAbonnement horaire) coachDe;
  final void Function(TarifAbonnement tarif) onSouscrire;
  final VoidCallback onDetails;

  // Images par défaut des catégories (mêmes que la page admin).
  // Public : la page Abonnements s'en sert aussi pour reconnaître
  // les catégories.
  static const defaultImages = {
    'category-pilates': 'assets/pilates.png',
    'category-musculation': 'assets/musculation.png',
    'category-tennis': 'assets/tennis.png',
    'category-enfant': 'assets/enfant.png',
    'category-yoga': 'assets/yoga.png',
    'category-full-acces': 'assets/full accés.png',
  };

  // Durées affichées : par séance, 1, 3, 6 et 12 mois.
  static const durations = [TarifAbonnement.dureeParSeance, 1, 3, 6, 12];

  // Catégories qui affichent toujours la section "Horaires des séances".
  static const _withSchedule = {
    'category-enfant',
    'category-yoga',
    'category-pilates',
  };

  // Le texte d'un horaire, ex : "Lundi · 18:00–19:00 · Ons · 10 places"
  String _horaireTexte(HoraireAbonnement h) {
    final coach = coachDe(h);
    return '${h.jour} · ${h.heureDebut}–${h.heureFin}'
        '${coach == null ? '' : ' · $coach'}'
        '${h.capacite == null ? '' : ' · ${h.capacite} places'}';
  }

  @override
  Widget build(BuildContext context) {
    final needsSchedule = _withSchedule.contains(abonnement.id);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // L'image en haut de la carte
          SizedBox(height: 185, child: _AbonnementImage(abonnement)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Titre + icône "détails" (œil)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        abonnement.type,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Consulter les détails',
                      onPressed: onDetails,
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                  ],
                ),
                Text(
                  abonnement.description.isEmpty
                      ? 'Description bientôt disponible.'
                      : abonnement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Les formules : une ligne par durée
                Text(
                  'Formules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final duration in durations)
                  _FormuleRow(
                    abonnement: abonnement,
                    duree: duration,
                    onSouscrire: onSouscrire,
                  ),

                // Les horaires (s'il y en a, ou si la catégorie doit en afficher)
                if (abonnement.horaires.isNotEmpty || needsSchedule) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Horaires des séances',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  if (abonnement.horaires.isEmpty)
                    const Text('Horaires bientôt disponibles.')
                  else
                    for (final schedule in abonnement.horaires)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _horaireTexte(schedule),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Fenêtre "détails" (icône œil)
// -----------------------------------------------------------------------------
void showAbonnementDetails(
    BuildContext context,
    Abonnement abonnement, {
      required String? Function(HoraireAbonnement horaire) coachDe,
      required void Function(TarifAbonnement tarif) onSouscrire,
    }) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image arrondie
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(height: 190, child: _AbonnementImage(abonnement)),
            ),
            const SizedBox(height: 16),
            Text(
              abonnement.type,
              style: Theme.of(sheetContext).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(abonnement.description),
            const SizedBox(height: 16),

            // Tarifs : une ligne par durée
            Text('Tarifs', style: Theme.of(sheetContext).textTheme.titleMedium),
            for (final duration in AbonnementCategoryCard.durations)
              _FormuleRow(
                abonnement: abonnement,
                duree: duration,
                onSouscrire: onSouscrire,
              ),

            // Horaires (seulement s'il y en a)
            if (abonnement.horaires.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Horaires des séances',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              for (final schedule in abonnement.horaires)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(
                    '${schedule.jour} · ${schedule.heureDebut}–${schedule.heureFin}',
                  ),
                  subtitle: Text(
                    [
                      if (coachDe(schedule) != null)
                        'Coach : ${coachDe(schedule)}',
                      if (schedule.capacite != null)
                        'Capacité : ${schedule.capacite}',
                    ].join(' · '),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );
}


// Une ligne de prix :  [ durée ........ ] [ Souscrire ] [ prix ]

class _FormuleRow extends StatelessWidget {
  const _FormuleRow({
    required this.abonnement,
    required this.duree, // 0 = par séance, 1, 3, 6 ou 12 mois
    required this.onSouscrire,
  });

  final Abonnement abonnement;
  final int duree;
  final void Function(TarifAbonnement tarif) onSouscrire;

  @override
  Widget build(BuildContext context) {
    // Le tarif défini par l'admin pour cette durée (null s'il n'y en a pas)
    final tariff = abonnement.tarifPour(duree);
    final durationLabel =
        tariff?.dureeLabel ??
            TarifAbonnement(dureeMois: duree, prix: null).dureeLabel;

    // On ne peut souscrire que si l'admin a défini un prix.
    final canSubscribe = tariff?.prix != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              durationLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // Bouton Souscrire (devant le prix)
          if (canSubscribe)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => onSouscrire(tariff!),
                style: ElevatedButton.styleFrom(
                  // Le thème force les boutons à prendre toute la largeur
                  // (Size.fromHeight) : on annule ça ici.
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.primaryDark,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Souscrire'),
              ),
            ),
          const SizedBox(width: 10),
          // Largeur fixe pour que tous les prix soient alignés.
          SizedBox(
            width: 80,
            child: Text(
              canSubscribe ? Formatters.price(tariff!.prix!) : 'À définir',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// L'image d'un abonnement : imageAsset > imageUrl > image par défaut > icône
class _AbonnementImage extends StatelessWidget {
  const _AbonnementImage(this.abonnement);

  final Abonnement abonnement;

  @override
  Widget build(BuildContext context) {
    // 1) Image du projet (dossier assets) choisie dans la fiche
    final imageAsset = abonnement.imageAsset?.isNotEmpty == true
        ? abonnement.imageAsset
        : null;
    if (imageAsset != null) {
      return Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => ImageIntrouvable(chemin: imageAsset),
      );
    }

    // 2) Image sur Internet
    final url = abonnement.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => ImageIntrouvable(chemin: url),
      );
    }

    // 3) Image par défaut de la catégorie
    final defaultImage = AbonnementCategoryCard.defaultImages[abonnement.id];
    if (defaultImage != null) {
      return Image.asset(
        defaultImage,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => ImageIntrouvable(chemin: defaultImage),
      );
    }

    // 4) Sinon : une icône sur fond vert clair
    return Container(
      color: const Color(0xFFE9F2DB),
      child: const Center(
        child: Icon(Icons.fitness_center, size: 52, color: AppColors.accent),
      ),
    );
  }
}

/// Affiché à la place d'une image qu'on n'arrive pas à charger.
/// (Public : la bannière de la page Abonnements s'en sert aussi.)
class ImageIntrouvable extends StatelessWidget {
  const ImageIntrouvable({
    super.key,
    required this.chemin, // le chemin de l'image qui manque
    this.banner = false, // true = version foncée pour la grande bannière
  });

  final String chemin;
  final bool banner;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: banner ? AppColors.primaryDark : const Color(0xFFE9F2DB),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: banner ? 38 : 32,
            color: banner ? Colors.white : AppColors.accent,
          ),
          const SizedBox(height: 6),
          Text(
            'Image introuvable : $chemin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: banner ? Colors.white : AppColors.primaryDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}