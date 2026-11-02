import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/abonnement.dart';
import '../models/adherent.dart';
import '../models/coach.dart';
import '../models/seance.dart';

///
/// Il fait deux choses :
///  ECOUTER Firestore : dès qu'une donnée change (ajout, modification,
///     suppression), les listes ci-dessous se mettent à jour et les écrans
///     se redessinent tout seuls (notifyListeners).
///   ÉCRIRE dans Firestore quand l'admin ajoute, modifie ou supprime.
///
/// Les écrans n'ont PAS changé : ils appellent les mêmes méthodes qu'avant
/// (saveCoach, deleteSeance, ...).
class AdminStore extends ChangeNotifier {
  AdminStore._() {
    // À chaque connexion / déconnexion de Firebase :
    //  - on arrête les anciennes écoutes et on vide les listes,
    //  - puis, si quelqu'un est connecté, on démarre l'écoute de Firestore.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _arreterEcoute();
      if (user != null) _demarrerEcoute();
    });
  }

  static final AdminStore instance = AdminStore._();

  // Raccourci vers la base Firestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Listes en mémoire : simple COPIE de ce qui est dans Firestore.
  final List<Abonnement> _abonnements = [];
  final List<Coach> _coachs = [];
  final List<Adherent> _adherents = [];
  final List<Seance> _seances = [];

  // Les "écoutes" ouvertes vers Firestore (gardées pour pouvoir les fermer).
  final List<StreamSubscription<dynamic>> _flux = [];
  String? _abonnementError;
  String? _abonnementReadError;
  bool _abonnementsLoaded = false;
  Future<void>? _subscriptionInitialization;

  //  Connexion à Firestore

  /// Écoute UNE collection. À chaque changement côté Firestore :
  /// on remplace la liste locale par le contenu reçu, puis on prévient les écrans.
  void _ecouter<T>(
    String collection, // nom de la collection Firestore
    List<T> liste, // la liste locale à remplir
    T Function(String id, Map<String, dynamic> data) convertir, // fromMap
  ) {
    final sub = _db
        .collection(collection)
        .snapshots()
        .listen(
          (snap) {
            final decodedItems = <T>[];
            final invalidDocumentIds = <String>[];
            for (final document in snap.docs) {
              try {
                decodedItems.add(convertir(document.id, document.data()));
              } catch (error, stackTrace) {
                debugPrint(
                  'Désérialisation Firestore '
                  '($collection/${document.id}) : $error\n$stackTrace',
                );
                if (collection == 'abonnements') {
                  invalidDocumentIds.add(document.id);
                }
              }
            }
            liste
              ..clear()
              ..addAll(decodedItems);
            if (collection == 'abonnements') {
              _abonnementsLoaded = true;
              _abonnementReadError = invalidDocumentIds.isEmpty
                  ? null
                  : 'Certains abonnements Firestore n’ont pas pu être lus '
                        '(${invalidDocumentIds.join(', ')}). Vérifiez leur '
                        'structure et leurs champs dans la collection abonnements.';
            }
            notifyListeners(); // "les données ont changé, redessinez-vous"
          },
          // Si Firestore refuse , on l'affiche en console.
          onError: (e) {
            debugPrint('Firestore ($collection) : $e');
            if (collection == 'abonnements') {
              _abonnementReadError = 'Erreur de lecture Firestore : $e';
              _abonnementsLoaded = true;
              notifyListeners();
            }
          },
        );
    _flux.add(sub);
  }

  /// Démarre l'écoute des 4 collections.
  void _demarrerEcoute() {
    _ecouter('abonnements', _abonnements, Abonnement.fromMap);
    _ecouter('coachs', _coachs, Coach.fromMap);
    _ecouter('adherents', _adherents, Adherent.fromMap);
    _ecouter('seances', _seances, Seance.fromMap);
  }

  /// Arrête toutes les écoutes et vide les listes (utile à la déconnexion).
  void _arreterEcoute() {
    for (final sub in _flux) {
      sub.cancel();
    }
    _flux.clear();
    _abonnements.clear();
    _coachs.clear();
    _adherents.clear();
    _seances.clear();
    _abonnementError = null;
    _abonnementReadError = null;
    _abonnementsLoaded = false;
    notifyListeners();
  }

  /// Lance une écriture Firestore et affiche l'erreur
  //envoyer des donnees a firestore
  void _ecrire(Future<void> ecriture) {
    ecriture.catchError((e) => debugPrint('Écriture Firestore : $e'));
  }

  //Lecture
  List<Abonnement> get abonnements => List.unmodifiable(_abonnements);
  String? get abonnementError => _abonnementError ?? _abonnementReadError;
  bool get abonnementsLoaded => _abonnementsLoaded;
  List<Coach> get coachs => List.unmodifiable(
    _coachs,
  ); //List.unmodifiable(...) empêche un écran de modifier la liste par erreur
  List<Adherent> get adherents => List.unmodifiable(_adherents);

  List<Seance> get seances {
    final list = [..._seances];
    list.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    return list;
  }

  /// Fabrique un identifiant unique pour un nouveau document.
  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Abonnement? abonnementById(String? id) {
    //retrouver un abonnement avec son identifiant
    if (id == null) return null;
    for (final a in _abonnements) {
      if (a.id == id) return a;
    }
    return null;
  }

  Coach? coachById(String id) {
    for (final c in _coachs) {
      if (c.id == id) return c;
    }
    return null;
  }

  String? nomDuCoach(String? coachId, {String? secours}) =>
      coachById(coachId ?? '')?.nomComplet ?? secours;

  /// Date de fin = date de début + durée de l'abonnement.
  DateTime? finAbonnement(Adherent a) {
    final plan = abonnementById(a.abonnementId);
    final debut = a.dateDebutAbonnement;
    if (plan == null || debut == null) return null;
    final duree = a.dureeAbonnementMois ?? plan.dureeMois;
    return DateTime(debut.year, debut.month + duree, debut.day);
  }

  StatutAbonnement statut(Adherent a) {
    final fin = finAbonnement(a);
    if (fin == null) return StatutAbonnement.aucun; //Pas de date de fin signifie pas d’abonnement, donc le statut est « Sans abonnement ».
    return fin.isBefore(today)
        ? StatutAbonnement.expire
        : StatutAbonnement.actif;
  } //On compare la date de fin avec aujourd’hui :

  // Si la date de fin est avant aujourd’hui, l’abonnement est expiré.
  //  Sinon, il est actif.

  //compare le jour ET l'heure de début de la séance
  bool estPassee(Seance s) => s.dateHeure.isBefore(DateTime.now());
  int nbSeancesDuCoach(String coachId) =>
      _seances.where((s) => s.coachId == coachId).length;

  int nbCreneauxDuCoach(String coachId) => _abonnements.fold<int>(
    0,
    (total, abonnement) =>
        total +
        abonnement.horaires
            .where((horaire) => horaire.coachId == coachId)
            .length,
  );

  int nbAdherentsDeLAbonnement(String abonnementId) =>
      _adherents.where((a) => a.abonnementId == abonnementId).length;

  //  Statistiques du tableau de bord
  int get nbAdherents => _adherents.length; //le nombre d’éléments de la liste
  int get nbCoachs => _coachs.length;

  int get nbAbonnementsActifs =>
      _adherents.where((a) => statut(a) == StatutAbonnement.actif).length;

  int get nbAbonnementsExpires =>
      _adherents.where((a) => statut(a) == StatutAbonnement.expire).length;

  List<Seance> get seancesAVenir =>
      seances.where((s) => !estPassee(s)).toList();

  int get nbSeancesProgrammees => seancesAVenir.length;

  int get nbReservations =>
      seancesAVenir.fold<int>(0, (total, s) => total + s.inscrits);

  Map<String, int> get reservationsParType {
    //Cette méthode calcule le nombre de réservations pour chaque type de séance
    final map = <String, int>{};
    for (final s in seancesAVenir) {
      map[s.type] = (map[s.type] ?? 0) + s.inscrits;
    }
    return map;
  }

  Map<String, int> get adherentsParAbonnement {
    final map = <String, int>{};
    for (final a in _adherents) {
      final label = abonnementById(a.abonnementId)?.type ?? 'Sans abonnement';
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  //  Écriture : Adhérents
  // set() = crée le document s'il n'existe pas, le remplace sinon.
  // Pas besoin de modifier les listes ici : Firestore nous renvoie le
  // changement via l'écoute (_ecouter), ce qui met l'écran à jour.
  void saveAdherent(Adherent a) {
    _ecrire(_db.collection('adherents').doc(a.id).set(a.toMap()));
  }

  void toggleAdherentActif(String id) {
    //Cette méthode active ou désactive un adhérent : s’il est actif, il devient inactif, et inversement
    final i = _adherents.indexWhere((x) => x.id == id);
    if (i == -1) return;
    // update() ne modifie que le champ indiqué, le reste est conservé.
    _ecrire(
      _db.collection('adherents').doc(id).update({
        'actif': !_adherents[i].actif,
      }),
    );
  }

  void deleteAdherent(String id) {
    _ecrire(_db.collection('adherents').doc(id).delete());
  }

  // Écriture : Coachs
  //toMap() les traduit dans le format de Firestore.
  void saveCoach(Coach c) {
    _ecrire(_db.collection('coachs').doc(c.id).set(c.toMap()));
  }

  /// Renvoie un message d'erreur si la suppression est impossible.
  String? deleteCoach(String id) {
    if (nbSeancesDuCoach(id) > 0) {
      return "Impossible : ce coach anime encore des séances. Modifiez ou supprimez ces séances d'abord.";
    }
    final scheduleCount = nbCreneauxDuCoach(id);
    if (scheduleCount > 0) {
      return "Impossible : ce coach est affecté à $scheduleCount créneau(x) d'abonnement. Retirez-le d'abord de ces abonnements.";
    }
    _ecrire(_db.collection('coachs').doc(id).delete());
    return null;
  }

  //  Écriture : Séances
  void saveSeance(Seance s) {
    _ecrire(_db.collection('seances').doc(s.id).set(s.toMap()));
  }

  void deleteSeance(String id) {
    _ecrire(_db.collection('seances').doc(id).delete());
  }

  // Écriture : Abonnements
  Future<void> saveAbonnement(Abonnement a) async {
    final data = a.toMap()
      ..['updatedAt'] = FieldValue.serverTimestamp()
      ..['createdAt'] = a.createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(a.createdAt!);
    await _db
        .collection('abonnements')
        .doc(a.id)
        .set(data, SetOptions(merge: true));
  }

  Future<void> deleteAbonnement(String id) async {
    final subscription = _db.collection('abonnements').doc(id);
    final references = await _db
        .collection('adherents')
        .where('abonnementId', isEqualTo: id)
        .limit(1)
        .get();
    if (references.docs.isNotEmpty || nbAdherentsDeLAbonnement(id) > 0) {
      throw StateError(
        "Impossible : des adhérents utilisent encore cet abonnement.",
      );
    }

    final initializationState = _db
        .collection('configuration')
        .doc('subscriptionCategories');

    await _db.runTransaction((transaction) async {
      final savedSubscription = await transaction.get(subscription);
      if (!savedSubscription.exists) return;

      DocumentSnapshot<Map<String, dynamic>>? state;
      if (_defaultCategoryIds.contains(id)) {
        state = await transaction.get(initializationState);
      }

      transaction.delete(subscription);
      if (state != null) {
        final deleted = List<String>.from(
          state.data()?['deletedCategoryIds'] as List? ?? const <String>[],
        );
        if (!deleted.contains(id)) deleted.add(id);
        transaction.set(initializationState, {
          'deletedCategoryIds': deleted,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<String> uploadAbonnementImage(
    String id,
    Uint8List bytes, {
    required String contentType,
  }) async {
    final reference = FirebaseStorage.instance.ref().child(
      'abonnements/$id/image',
    );
    await reference.putData(bytes, SettableMetadata(contentType: contentType));
    return reference.getDownloadURL();
  }

  static const _defaultCategoryIds = [
    'category-pilates',
    'category-musculation',
    'category-tennis',
    'category-enfant',
    'category-yoga',
    'category-full-acces',
  ];

  static const _defaultDurations = [
    TarifAbonnement.dureeParSeance,
    1,
    3,
    6,
    12,
  ];

  static const _defaultSubscriptions = [
    (
      slug: 'pilates',
      name: 'pilates',
      description: 'Séances de Pilates pour améliorer la posture, renforcer les muscles profonds, développer la souplesse et améliorer l’équilibre.',
      image: 'assets/pilates.png',
      prices: [20.0, 80.0, 210.0, 390.0, 720.0],
    ),
    (
      slug: 'musculation',
      name: 'musculation',
      description: 'Accès à l’espace de musculation équipé pour développer la force, améliorer l’endurance et atteindre ses objectifs physiques.',
      image: 'assets/musculation.png',
      prices: [15.0, 70.0, 190.0, 350.0, 650.0],
    ),
    (
      slug: 'tennis',
      name: 'tennis',
      description: 'Séances de tennis pour développer la coordination, les réflexes, l’endurance et les techniques de jeu.',
      image: 'assets/tennis.png',
      prices: [25.0, 100.0, 270.0, 500.0, 900.0],
    ),
    (
      slug: 'enfant',
      name: 'enfant',
      description: 'Activités sportives adaptées aux enfants, encadrées par des professionnels dans un environnement sécurisé et motivant.',
      image: 'assets/enfant.png',
      prices: [15.0, 60.0, 160.0, 300.0, 550.0],
    ),
    (
      slug: 'yoga',
      name: 'yoga',
      description: 'Séances de yoga favorisant la relaxation, la respiration, la souplesse et l’équilibre physique et mental.',
      image: 'assets/yoga.png',
      prices: [20.0, 75.0, 200.0, 370.0, 680.0],
    ),
    (
      slug: 'full-acces',
      name: 'full accés',
      description: 'Formule complète permettant de profiter des différentes activités et installations de FitClub, selon les conditions d’accès définies par la salle.',
      image: 'assets/full accés.png',
      prices: [30.0, 150.0, 400.0, 750.0, 1400.0],
    ),
  ];

  Future<void> initializeDefaultSubscriptions() {
    final activeInitialization = _subscriptionInitialization;
    if (activeInitialization != null) return activeInitialization;

    final initialization = _initializeDefaultSubscriptions();
    _subscriptionInitialization = initialization;
    return initialization.whenComplete(() {
      if (identical(_subscriptionInitialization, initialization)) {
        _subscriptionInitialization = null;
      }
    });
  }

  Future<void> _initializeDefaultSubscriptions() async {
    final collection = _db.collection('abonnements');
    final stateReference = _db
        .collection('configuration')
        .doc('subscriptionCategories');

    try {
      await _db.runTransaction((transaction) async {
        final state = await transaction.get(stateReference);
        final deletedIds = Set<String>.from(
          state.data()?['deletedCategoryIds'] as List? ?? const <String>[],
        );
        final references = [
          for (final category in _defaultSubscriptions)
            collection.doc('category-${category.slug}'),
        ];
        final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
        for (final reference in references) {
          snapshots.add(await transaction.get(reference));
        }

        final now = DateTime.now();
        for (var index = 0; index < _defaultSubscriptions.length; index++) {
          final reference = references[index];
          if (deletedIds.contains(reference.id)) {
            continue;
          }

          final category = _defaultSubscriptions[index];
          if (snapshots[index].exists) {
            final existing = snapshots[index].data()!;
            final existingFormulas = existing['formules'];
            final hasConfiguredPrice =
                existingFormulas is List &&
                existingFormulas.any(
                  (formula) => formula is Map && formula['prix'] != null,
                );
            final isUneditedSeed =
                existing['isCategory'] == true &&
                existing['updatedAt'] == null &&
                !hasConfiguredPrice;
            final hasLocalImage =
                existing['imageAsset'] is String &&
                (existing['imageAsset'] as String).trim().isNotEmpty;
            final hasRemoteImage =
                existing['imageUrl'] is String &&
                (existing['imageUrl'] as String).trim().isNotEmpty;
            final updates = <String, dynamic>{};
            if (isUneditedSeed) {
              updates.addAll({
                'prix': category.prices[1],
                'formules': [
                  for (
                    var priceIndex = 0;
                    priceIndex < category.prices.length;
                    priceIndex++
                  )
                    TarifAbonnement(
                      dureeMois: _defaultDurations[priceIndex],
                      prix: category.prices[priceIndex],
                    ).toMap(),
                ],
                'isDemoPricing': true,
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
            if (!hasLocalImage && !hasRemoteImage) {
              updates['imageAsset'] = category.image;
            }
            if (updates.isNotEmpty) transaction.update(reference, updates);
            continue;
          }

          final data =
              Abonnement(
                  id: reference.id,
                  type: category.name,
                  prix: category.prices[1],
                  dureeMois: 1,
                  avantages: category.description,
                  description: category.description,
                  imageAsset: category.image,
                  formules: [
                    for (
                      var priceIndex = 0;
                      priceIndex < category.prices.length;
                      priceIndex++
                    )
                      TarifAbonnement(
                        dureeMois: _defaultDurations[priceIndex],
                        prix: category.prices[priceIndex],
                      ),
                  ],
                  isCategory: true,
                  createdAt: now,
                ).toMap()
                ..['categorySlug'] = category.slug
                ..['isDemoPricing'] = true;
          transaction.set(reference, data);
        }

        transaction.set(stateReference, {
          'initializedAt':
              state.data()?['initializedAt'] ?? FieldValue.serverTimestamp(),
          'deletedCategoryIds': deletedIds.toList(),
        }, SetOptions(merge: true));
      });
      _abonnementError = null;
    } on FirebaseException catch (error) {
      _abonnementError =
          "Impossible d’initialiser les abonnements dans Firestore (${error.code}). "
          "Vérifiez votre connexion et les règles Firestore.";
      debugPrint('Initialisation des abonnements : $error');
      rethrow;
    } catch (error, stackTrace) {
      _abonnementError =
          'Impossible de préparer les abonnements Firestore : $error';
      debugPrint('Initialisation des abonnements : $error\n$stackTrace');
      rethrow;
    } finally {
      notifyListeners();
    }
  }
}
