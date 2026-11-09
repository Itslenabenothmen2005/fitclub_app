import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/admin_item_card.dart';
import '../../widgets/admin/avatars.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../widgets/admin/empty_state.dart';
import 'subscription_form_screen.dart';
import '../adherent/paiement_screen.dart';

class SubscriptionsScreen extends StatefulWidget {const SubscriptionsScreen({super.key, this.adherentMode = false});
final bool adherentMode; // true = vue adhérent (lecture seule + Souscrire)

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _store = AdminStore.instance;
  bool _isInitializing = true;
  String? _initializationError;

  static const _defaultCategoryImages = {
    'category-pilates': 'assets/pilates.png',
    'category-musculation': 'assets/musculation.png',
    'category-tennis': 'assets/tennis.png',
    'category-enfant': 'assets/enfant.png',
    'category-yoga': 'assets/yoga.png',
    'category-full-acces': 'assets/full accés.png',
  };

  @override
  void initState() {
    super.initState();
    _initializeSubscriptions();
  }

  Future<void> _initializeSubscriptions() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        _initializationError =
            'Connectez-vous avec un compte administrateur pour charger et '
            'initialiser les abonnements.';
        return;
      }
      await _store.initializeDefaultSubscriptions();
      _initializationError = null;
    } on FirebaseException catch (error, stackTrace) {
      _initializationError =
          'Échec de l’initialisation Firestore (${error.code}) : '
          '${error.message ?? 'vérifiez votre connexion et les règles de la base.'}';
      debugPrint('Initialisation de la page Abonnements : $error\n$stackTrace');
      if (mounted) {
        _snack(_initializationError!);
      }
    } catch (error, stackTrace) {
      _initializationError =
          'Échec de l’initialisation des abonnements : $error';
      debugPrint('Initialisation de la page Abonnements : $error\n$stackTrace');
      if (mounted) _snack(_initializationError!);
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Abonnement? abonnement]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SubscriptionFormScreen(abonnement: abonnement),
      ),
    );
    if (message != null && mounted) _snack(message);
  }

  Future<void> _delete(Abonnement abonnement) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer cet abonnement ?',
      message:
          "L’abonnement « ${abonnement.type} » sera supprimé définitivement. "
          'Les abonnements utilisés par des adhérents sont protégés.',
    );
    if (!confirmed || !mounted) return;
    try {
      await _store.deleteAbonnement(abonnement.id);
      if (mounted) _snack('Abonnement supprimé.');
    } on StateError catch (error) {
      if (mounted) _snack(error.message);
    } on FirebaseException catch (error) {
      if (mounted) {
        _snack(
          'Suppression impossible (${error.code}) : ${error.message ?? 'erreur Firebase.'}',
        );
      }
    }
  }

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
          errorBuilder: (_, error, stackTrace) {
            debugPrint(
              'Asset introuvable : assets/Bienvenue.png ($error)\n$stackTrace',
            );
            return _missingImage('assets/Bienvenue.png', banner: true);
          },
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
                    IconButton(
                      tooltip: 'Consulter les détails',
                      onPressed: () => _showDetails(abonnement),
                      icon: const Icon(Icons.visibility_outlined),
                    ),
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _openForm(abonnement),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _delete(abonnement),
                      color: AppColors.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                Text(
                  abonnement.description.isEmpty
                      ? 'Description à renseigner par l’administrateur.'
                      : abonnement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (abonnement.isDemoPricing) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Tarifs de démonstration modifiables',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Formules',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                for (final duration in const [
                  TarifAbonnement.dureeParSeance,
                  1,
                  3,
                  6,
                  12,
                ])
                  _priceRow(abonnement, duration),
                if (abonnement.horaires.isNotEmpty || needsSchedule) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Horaires des séances',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  if (abonnement.horaires.isEmpty)
                    const Text('À renseigner par l’administrateur.')
                  else
                    for (final schedule in abonnement.horaires)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${schedule.jour} · ${schedule.heureDebut}–${schedule.heureFin}'
                          '${_store.nomDuCoach(schedule.coachId, secours: schedule.coach) == null ? '' : ' · ${_store.nomDuCoach(schedule.coachId, secours: schedule.coach)}'}'
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

  Widget _priceRow(Abonnement abonnement, int duration) {
    final tariff = abonnement.tarifPour(duration);
    final durationLabel =
        tariff?.dureeLabel ??
        TarifAbonnement(dureeMois: duration, prix: null).dureeLabel;
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
          Text(
            tariff?.prix == null
                ? 'À définir'
                : Formatters.price(tariff!.prix!),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

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
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Asset introuvable : $imageAsset ($error)\n$stackTrace');
          return _missingImage(imageAsset);
        },
      );
    }
    if (abonnement.imageUrl != null && abonnement.imageUrl!.isNotEmpty) {
      return Image.network(
        abonnement.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          debugPrint(
            'Image distante introuvable : ${abonnement.imageUrl} '
            '($error)\n$stackTrace',
          );
          return _missingImage(abonnement.imageUrl!);
        },
      );
    }
    final defaultImage = _defaultCategoryImages[abonnement.id];
    if (defaultImage != null) {
      return Image.asset(
        defaultImage,
        fit: BoxFit.cover,
        errorBuilder: (_, error, stackTrace) {
          debugPrint('Asset introuvable : $defaultImage ($error)\n$stackTrace');
          return _missingImage(defaultImage);
        },
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

  void _showDetails(Abonnement abonnement) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(abonnement.description),
              const SizedBox(height: 16),
              Text('Tarifs', style: Theme.of(context).textTheme.titleMedium),
              for (final duration in const [
                TarifAbonnement.dureeParSeance,
                1,
                3,
                6,
                12,
              ])
                _priceRow(abonnement, duration),
              if (abonnement.horaires.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Horaires des séances',
                  style: Theme.of(context).textTheme.titleMedium,
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
                        if (_store.nomDuCoach(
                              schedule.coachId,
                              secours: schedule.coach,
                            )
                            case final coach?)
                          'Coach : $coach',
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

  Widget _legacySubscriptions(List<Abonnement> legacy) {
    if (legacy.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        Text(
          'Formules existantes conservées',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final abonnement in legacy)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AdminItemCard(
              leading: const IconAvatar(icon: Icons.card_membership_outlined),
              title: abonnement.type,
              details: [
                '${Formatters.price(abonnement.prix)} · ${abonnement.dureeLabel}',
                abonnement.avantages,
              ],
              actions: [
                ItemAction(
                  label: 'Modifier',
                  icon: Icons.edit_outlined,
                  onTap: () => _openForm(abonnement),
                ),
                ItemAction(
                  label: 'Supprimer',
                  icon: Icons.delete_outline,
                  destructive: true,
                  onTap: () => _delete(abonnement),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _store,
    builder: (context, _) {
      final all = _store.abonnements;
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
              const defaults = [
                'category-pilates',
                'category-musculation',
                'category-tennis',
                'category-enfant',
                'category-yoga',
                'category-full-acces',
              ];
              final aIndex = defaults.indexOf(a.id);
              final bIndex = defaults.indexOf(b.id);
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
      final subscriptionError = _initializationError ?? _store.abonnementError;
      return Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryDark,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un abonnement'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
            if (subscriptionError != null) ...[
              const SizedBox(height: 12),
              Material(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    subscriptionError,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (categories.isEmpty &&
                (_isInitializing ||
                    (!_store.abonnementsLoaded && subscriptionError == null)))
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (categories.isEmpty && subscriptionError != null)
              EmptyState(
                icon: Icons.cloud_off_outlined,
                message: subscriptionError,
              )
            else if (categories.isEmpty)
              const EmptyState(
                icon: Icons.card_membership_outlined,
                message:
                    'Firestore ne retourne aucune catégorie. Si vous attendiez '
                    'les six catégories initiales, vérifiez l’authentification '
                    'administrateur, les règles de lecture/écriture et le '
                    'résultat de l’initialisation. Les catégories supprimées '
                    'volontairement ne sont pas recréées.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 760 ? 2 : 1;
                  final cardWidth = columns == 1
                      ? constraints.maxWidth
                      : (constraints.maxWidth - 16) / 2;
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
            _legacySubscriptions(legacy),
          ],
        ),
      );
    },
  );
}
