import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seance.dart';

/// Message d'erreur simple à afficher à l'utilisateur
/// (ex : "Séance complète").
class ReservationFailure implements Exception {
  final String message;
  const ReservationFailure(this.message);
  @override
  String toString() => message;
}

class ReservationService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Écoute en temps réel les séances que CET adhérent a réservées.
  /// On renvoie juste la liste des ids de séances (ex : {"seance-12", "seance-15"}).
  Stream<Set<String>> watchMesReservations(String adherentId) {
    return _db
        .collection('reservations')
        .where('adherentId', isEqualTo: adherentId) // seulement les miennes
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => doc['seanceId'] as String).toSet());
  }

  /// RÉSERVER une séance.
  /// Une "transaction" = tout se passe d'un coup ou rien du tout.
  /// Ça évite que 2 personnes prennent la dernière place en même temps.
  Future<void> reserver({
    required String seanceId,
    required String adherentId,
  }) {
    final seanceRef = _db.collection('seances').doc(seanceId);
    // L'id de la réservation = séance + adhérent -> impossible de réserver 2 fois
    final reservationRef =
    _db.collection('reservations').doc('${seanceId}_$adherentId');

    return _db.runTransaction((tx) async {
      // 1) LIRE d'abord (dans une transaction, on lit avant d'écrire)
      final seanceSnap = await tx.get(seanceRef);
      final reservationSnap = await tx.get(reservationRef);

      // 2) VÉRIFIER
      if (!seanceSnap.exists) {
        throw const ReservationFailure("Cette séance n'existe plus.");
      }
      final seance = Seance.fromMap(seanceSnap.id, seanceSnap.data()!);

      if (reservationSnap.exists) {
        throw const ReservationFailure('Vous avez déjà réservé cette séance.');
      }
      if (seance.complete) {
        throw const ReservationFailure('Désolé, cette séance est complète.');
      }

      // 3) ÉCRIRE : créer la réservation + ajouter 1 inscrit à la séance
      tx.set(reservationRef, {
        'seanceId': seanceId,
        'adherentId': adherentId,
        'dateReservation': FieldValue.serverTimestamp(),
      });
      tx.update(seanceRef, {'inscrits': FieldValue.increment(1)});
    });
  }

  /// ANNULER une réservation (on rend la place : inscrits - 1).
  Future<void> annuler({
    required String seanceId,
    required String adherentId,
  }) {
    final seanceRef = _db.collection('seances').doc(seanceId);
    final reservationRef =
    _db.collection('reservations').doc('${seanceId}_$adherentId');

    return _db.runTransaction((tx) async {
      final reservationSnap = await tx.get(reservationRef);
      if (!reservationSnap.exists) return; // rien à annuler

      tx.delete(reservationRef);
      tx.update(seanceRef, {'inscrits': FieldValue.increment(-1)});
    });
  }
}