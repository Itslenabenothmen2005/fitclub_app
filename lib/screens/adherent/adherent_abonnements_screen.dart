// Page "Abonnements" de l'ESPACE ADHÉRENT.
// = la page admin (mêmes données via AdminStore), sans Ajouter / Modifier /
// Supprimer, avec un bouton "Souscrire" devant chaque prix qui ouvre la
// page de paiement.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../services/souscription_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import 'paiement_screen.dart';

class AdherentAbonnementsScreen extends StatelessWidget {
  const AdherentAbonnementsScreen({super.key});

  // Même source de données que la page admin.
  AdminStore get _store => AdminStore.instance;

  // Mêmes images par défaut que la page admin.
  static const _defaultCategoryImages = {
    'category-pilates': 'assets/pilates.png',
    'category-musculation': 'assets/musculation.png',
    'category-tennis': 'assets/tennis.png',
    'category-enfant': 'assets/enfant.png',
    'category-yoga': 'assets/yoga.png',
    'category-full-acces': 'assets/full accés.png',
  };

  // Même ordre d'affichage que la page admin.
  static const _defaultOrder = [
    'category-pilates',
    'category-musculation',
    'category-tennis',
    'category-enfant',
    'category-yoga',
    'category-full-acces',
  ];

  // Durées affichées : par séance, 1, 3, 6 et 12 mois.
  static const _durations = [TarifAbonnement.dureeParSeance, 1, 3, 6, 12];

  // ---------------------------------------------------------------------------
  // Clic sur "Souscrire" : on vérifie D'ABORD que l'adhérent n'a pas déjà
  // cet abonnement en cours. Si c'est le cas, on affiche le message et on
  // n'ouvre PAS la page de paiement.
  // ---------------------------------------------------------------------------
  Future<void> _souscrire(
      BuildContext context,
      Abonnement abonnement,
      TarifAbonnement tarif,
      ) async {
    // On garde ces objets AVANT l'attente (await) pour les utiliser après.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await SouscriptionService().verifierAbonnementActif(
          user: user,
          abonnement: abonnement,
          tarif: tarif,
        );
      } on AbonnementDejaActif catch (e) {
        // Déjà abonné : message, et on s'arrête ici.
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } catch (_) {
        // Erreur de lecture : on laisse passer, la vérification sera
        // refaite au moment du paiement.
      }
    }

    // Pas d'abonnement en cours : on ouvre la page de paiement.
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PaiementScreen(abonnement: abonnement, tarif: tarif),
      ),
    );
  }

  // Nom du coach d'un horaire (null si inconnu).
  String? _coach(HoraireAbonnement schedule) =>
      _store.nomDuCoach(schedule.coachId, secours: schedule.coach);

  // ---------------------------------------------------------------------------
  // Bandeau de bienvenue (identique à l'admin)
  // ---------------------------------------------------------------------------
  Widget _welcome(BuildContext context) => Container(
    width: double.infinity,
    height: 230,
    decoration: BoxDecoration(
      color: AppColors.primaryDark,
      borderRadius: BorderRadius.circular(22),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/Bienvenue.png',
          fit: BoxFit.cover,
          errorBuilder: (_, error, stackTrace) =>
              _missingImage('assets/Bienvenue.png', banner: true),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDark.withValues(alpha: 0.88),
                AppColors.primaryDark.withValues(alpha: 0.20),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BIENVENUE CHEZ FITCLUB',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Le mouvement, le bien-être et la progression au cœur de chaque séance. Découvrez nos activités et choisissez votre formule.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Carte d'une catégorie (natation, yoga...) : image, description, formules
  // ---------------------------------------------------------------------------
  Widget _categoryCard(BuildContext context, Abonnement abonnement) {
    final needsSchedule = {
      'category-enfant',
      'category-yoga',
      'category-pilates',
    }.contains(abonnement.id);

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
          SizedBox(height: 185, child: _subscriptionImage(abonnement)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                    // Seule l'icône "détails" (œil) est gardée.
                    IconButton(
                      tooltip: 'Consulter les détails',
                      onPressed: () => _showDetails(context, abonnement),
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
                Text(
                  'Formules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final duration in _durations)
                  _priceRow(context, abonnement, duration),
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
                          '${schedule.jour} · ${schedule.heureDebut}–${schedule.heureFin}'
                              '${_coach(schedule) == null ? '' : ' · ${_coach(schedule)}'}'
                              '${schedule.capacite == null ? '' : ' · ${schedule.capacite} places'}',
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

  // ---------------------------------------------------------------------------
  // Ligne de prix :  [ durée ........ ] [ Souscrire ] [ prix ]
  // ---------------------------------------------------------------------------
  Widget _priceRow(BuildContext context, Abonnement abonnement, int duration) {
    final tariff = abonnement.tarifPour(duration);
    final durationLabel =
        tariff?.dureeLabel ??
            TarifAbonnement(dureeMois: duration, prix: null).dureeLabel;

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
                onPressed: () => _souscrire(context, abonnement, tariff!),
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

  // ---------------------------------------------------------------------------
  // Image : imageAsset > imageUrl > image par défaut > icône
  // ---------------------------------------------------------------------------
  Widget _subscriptionImage(Abonnement abonnement) {
    final fallback = Container(
      color: const Color(0xFFE9F2DB),
      child: const Center(
        child: Icon(Icons.fitness_center, size: 52, color: AppColors.accent),
      ),
    );
    final imageAsset = abonnement.imageAsset?.isNotEmpty == true
        ? abonnement.imageAsset
        : null;
    if (imageAsset != null) {
      return Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _missingImage(imageAsset),
      );
    }
    if (abonnement.imageUrl != null && abonnement.imageUrl!.isNotEmpty) {
      return Image.network(
        abonnement.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _missingImage(abonnement.imageUrl!),
      );
    }
    final defaultImage = _defaultCategoryImages[abonnement.id];
    if (defaultImage != null) {
      return Image.asset(
        defaultImage,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _missingImage(defaultImage),
      );
    }
    return fallback;
  }

  Widget _missingImage(String path, {bool banner = false}) => Container(
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
          'Image introuvable : $path',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: banner ? Colors.white : AppColors.primaryDark,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  // ---------------------------------------------------------------------------
  // Fenêtre "détails" (icône œil)
  // ---------------------------------------------------------------------------
  void _showDetails(BuildContext context, Abonnement abonnement) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 190,
                  child: _subscriptionImage(abonnement),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                abonnement.type,
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(abonnement.description),
              const SizedBox(height: 16),
              Text(
                'Tarifs',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              for (final duration in _durations)
                _priceRow(sheetContext, abonnement, duration),
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
                        if (_coach(schedule) != null)
                          'Coach : ${_coach(schedule)}',
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

  // ---------------------------------------------------------------------------
  // Anciennes formules (sans catégorie) : carte simple + bouton Souscrire
  // ---------------------------------------------------------------------------
  Widget _legacySubscriptions(BuildContext context, List<Abonnement> legacy) {
    if (legacy.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text('Autres formules', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final abonnement in legacy)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.card_membership_outlined),
              title: Text(abonnement.type),
              subtitle: Text(
                '${Formatters.price(abonnement.prix)} · ${abonnement.dureeLabel}'
                    '${abonnement.avantages.isEmpty ? '' : '\n${abonnement.avantages}'}',
              ),
              isThreeLine: abonnement.avantages.isNotEmpty,
              trailing: ElevatedButton(
                onPressed: () => _souscrire(
                  context,
                  abonnement,
                  TarifAbonnement(
                    dureeMois: abonnement.dureeMois,
                    prix: abonnement.prix,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  // Même correction de largeur forcée par le thème.
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: const Text('Souscrire'),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD : même données que la page admin (AdminStore)
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ListenableBuilder : la page se redessine quand les données changent.
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final all = _store.abonnements;
          final error = _store.abonnementError;

          // Même tri catégories / anciennes formules que la page admin.
          final defaultIds = _defaultCategoryImages.keys.toSet();
          final categories =
          all
              .where(
                (item) =>
            item.id != 'category-boxe' &&
                (item.isCategory || defaultIds.contains(item.id)),
          )
              .toList()
            ..sort((a, b) {
              final aIndex = _defaultOrder.indexOf(a.id);
              final bIndex = _defaultOrder.indexOf(b.id);
              if (aIndex == -1 && bIndex == -1) {
                return a.type.compareTo(b.type);
              }
              if (aIndex == -1) return 1;
              if (bIndex == -1) return -1;
              return aIndex.compareTo(bIndex);
            });
          final legacy = all
              .where(
                (item) =>
            item.id == 'category-boxe' ||
                (!item.isCategory && !defaultIds.contains(item.id)),
          )
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _welcome(context),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nos abonnements',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Text(
                    '${categories.length} catégories',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              // Message d'erreur rouge (ex : permission-denied)
              if (error != null) ...[
                const SizedBox(height: 12),
                Material(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (categories.isEmpty &&
                  !_store.abonnementsLoaded &&
                  error == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: Text('Aucun abonnement disponible.')),
                )
              else
              // 1 colonne sur téléphone, 2 sur grand écran.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = constraints.maxWidth >= 760
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (final category in categories)
                          SizedBox(
                            width: cardWidth,
                            child: _categoryCard(context, category),
                          ),
                      ],
                    );
                  },
                ),
              _legacySubscriptions(context, legacy),
            ],
          );
        },
      ),
    );
  }
}