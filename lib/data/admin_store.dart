import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  //  Connexion à Firestore

  /// Écoute UNE collection. À chaque changement côté Firestore :
  /// on remplace la liste locale par le contenu reçu, puis on prévient les écrans.
  void _ecouter<T>(
      String collection, // nom de la collection Firestore
      List<T> liste, // la liste locale à remplir
      T Function(String id, Map<String, dynamic> data) convertir, // fromMap
      ) {
    final sub = _db.collection(collection).snapshots().listen(
          (snap) {
        liste
          ..clear()
          ..addAll(snap.docs.map((doc) => convertir(doc.id, doc.data())));
        notifyListeners(); // "les données ont changé, redessinez-vous"
      },
      // Si Firestore refuse , on l'affiche en console.
      onError: (e) => debugPrint('Firestore ($collection) : $e'),
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
    notifyListeners();
  }

  /// Lance une écriture Firestore et affiche l'erreur
//envoyer des donnees a firestore
  void _ecrire(Future<void> ecriture) {
    ecriture.catchError((e) => debugPrint('Écriture Firestore : $e'));
  }

  //Lecture
  List<Abonnement> get abonnements => List.unmodifiable(_abonnements);
  List<Coach> get coachs => List.unmodifiable(_coachs);//List.unmodifiable(...) empêche un écran de modifier la liste par erreur
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

  Abonnement? abonnementById(String? id) {//retrouver un abonnement avec son identifiant
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

  /// Date de fin = date de début + durée de l'abonnement.
  DateTime? finAbonnement(Adherent a) {
    final plan = abonnementById(a.abonnementId);
    final debut = a.dateDebutAbonnement;
    if (plan == null || debut == null) return null;
    return DateTime(debut.year, debut.month + plan.dureeMois, debut.day);
  }

  StatutAbonnement statut(Adherent a) {
    final fin = finAbonnement(a);
    if (fin == null) return StatutAbonnement.aucun;//Pas de date de fin signifie pas d’abonnement, donc le statut est « Sans abonnement ».
    return fin.isBefore(today) ? StatutAbonnement.expire : StatutAbonnement.actif;
  }//On compare la date de fin avec aujourd’hui :

 // Si la date de fin est avant aujourd’hui, l’abonnement est expiré.
//  Sinon, il est actif.

  //compare le jour ET l'heure de début de la séance
  bool estPassee(Seance s) => s.dateHeure.isBefore(DateTime.now());
  int nbSeancesDuCoach(String coachId) =>
      _seances.where((s) => s.coachId == coachId).length;

  int nbAdherentsDeLAbonnement(String abonnementId) =>
      _adherents.where((a) => a.abonnementId == abonnementId).length;

  //  Statistiques du tableau de bord
  int get nbAdherents => _adherents.length;//le nombre d’éléments de la liste
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

  Map<String, int> get reservationsParType {//Cette méthode calcule le nombre de réservations pour chaque type de séance
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

  void toggleAdherentActif(String id) {//Cette méthode active ou désactive un adhérent : s’il est actif, il devient inactif, et inversement
    final i = _adherents.indexWhere((x) => x.id == id);
    if (i == -1) return;
    // update() ne modifie que le champ indiqué, le reste est conservé.
    _ecrire(_db
        .collection('adherents')
        .doc(id)
        .update({'actif': !_adherents[i].actif}));
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
  void saveAbonnement(Abonnement a) {
    _ecrire(_db.collection('abonnements').doc(a.id).set(a.toMap()));
  }

  String? deleteAbonnement(String id) {
    if (nbAdherentsDeLAbonnement(id) > 0) {
      return "Impossible : des adhérents utilisent encore cet abonnement.";
    }
    _ecrire(_db.collection('abonnements').doc(id).delete());
    return null;
  }
}