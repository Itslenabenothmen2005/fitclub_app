import 'package:flutter/foundation.dart';

import '../models/abonnement.dart';
import '../models/adherent.dart';
import '../models/coach.dart';
import '../models/seance.dart';
import 'mock_data.dart';

/// Le "grand classeur" de l'application (en mémoire, sans backend).
/// Les écrans l'écoutent : dès qu'on le modifie, ils se redessinent.
/// Plus tard, ce fichier sera remplacé par des appels à Firestore.
class AdminStore extends ChangeNotifier {
  AdminStore._() {
    _abonnements.addAll(MockData.abonnements());
    _coachs.addAll(MockData.coachs());
    _adherents.addAll(MockData.adherents());
    _seances.addAll(MockData.seances());
  }

  static final AdminStore instance = AdminStore._();

  final List<Abonnement> _abonnements = [];
  final List<Coach> _coachs = [];
  final List<Adherent> _adherents = [];
  final List<Seance> _seances = [];

  // ---------- Lecture ----------
  List<Abonnement> get abonnements => List.unmodifiable(_abonnements);
  List<Coach> get coachs => List.unmodifiable(_coachs);
  List<Adherent> get adherents => List.unmodifiable(_adherents);

  List<Seance> get seances {
    final list = [..._seances];
    list.sort((a, b) => a.dateHeure.compareTo(b.dateHeure));
    return list;
  }

  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Abonnement? abonnementById(String? id) {
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
    if (fin == null) return StatutAbonnement.aucun;
    return fin.isBefore(today) ? StatutAbonnement.expire : StatutAbonnement.actif;
  }

  bool estPassee(Seance s) => s.date.isBefore(today);

  int nbSeancesDuCoach(String coachId) =>
      _seances.where((s) => s.coachId == coachId).length;

  int nbAdherentsDeLAbonnement(String abonnementId) =>
      _adherents.where((a) => a.abonnementId == abonnementId).length;

  // ---------- Statistiques du tableau de bord ----------
  int get nbAdherents => _adherents.length;
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

  // ---------- Adhérents ----------
  void saveAdherent(Adherent a) {
    final i = _adherents.indexWhere((x) => x.id == a.id);
    if (i == -1) {
      _adherents.add(a);
    } else {
      _adherents[i] = a;
    }
    notifyListeners();
  }

  void toggleAdherentActif(String id) {
    final i = _adherents.indexWhere((x) => x.id == id);
    if (i == -1) return;
    _adherents[i] = _adherents[i].withActif(!_adherents[i].actif);
    notifyListeners();
  }

  void deleteAdherent(String id) {
    _adherents.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ---------- Coachs ----------
  void saveCoach(Coach c) {
    final i = _coachs.indexWhere((x) => x.id == c.id);
    if (i == -1) {
      _coachs.add(c);
    } else {
      _coachs[i] = c;
    }
    notifyListeners();
  }

  /// Renvoie un message d'erreur si la suppression est impossible.
  String? deleteCoach(String id) {
    if (nbSeancesDuCoach(id) > 0) {
      return "Impossible : ce coach anime encore des séances. Modifiez ou supprimez ces séances d'abord.";
    }
    _coachs.removeWhere((x) => x.id == id);
    notifyListeners();
    return null;
  }

  // ---------- Séances ----------
  void saveSeance(Seance s) {
    final i = _seances.indexWhere((x) => x.id == s.id);
    if (i == -1) {
      _seances.add(s);
    } else {
      _seances[i] = s;
    }
    notifyListeners();
  }

  void deleteSeance(String id) {
    _seances.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  // ---------- Abonnements ----------
  void saveAbonnement(Abonnement a) {
    final i = _abonnements.indexWhere((x) => x.id == a.id);
    if (i == -1) {
      _abonnements.add(a);
    } else {
      _abonnements[i] = a;
    }
    notifyListeners();
  }

  String? deleteAbonnement(String id) {
    if (nbAdherentsDeLAbonnement(id) > 0) {
      return "Impossible : des adhérents utilisent encore cet abonnement.";
    }
    _abonnements.removeWhere((x) => x.id == id);
    notifyListeners();
    return null;
  }
}