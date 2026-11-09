import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/abonnement.dart';

/// Erreur lancée quand l'adhérent a déjà cet abonnement en cours.
/// Elle porte un message clair (avec la date de fin) à afficher à l'écran.
class AbonnementDejaActif implements Exception {
  const AbonnementDejaActif(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Enregistre une souscription dans Firestore après le paiement.
/// On ne stocke JAMAIS le numéro complet, la date d'expiration ni le CVC :
/// seulement les 4 derniers chiffres de la carte.
class SouscriptionService {
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Date de début + nombre de mois (même calcul que l'AdminStore).
  DateTime _ajouterMois(DateTime debut, int mois) =>
      DateTime(debut.year, debut.month + mois, debut.day);

  // ---------------------------------------------------------------------------
  // VÉRIFICATION : l'adhérent a-t-il déjà CET abonnement en cours ?
  // Appelée dès le clic sur "Souscrire" (avant d'ouvrir le formulaire),
  // puis une deuxième fois au moment du paiement (sécurité).
  // Lance AbonnementDejaActif si c'est le cas.
  // ---------------------------------------------------------------------------
  Future<void> verifierAbonnementActif({
    required User user,
    required Abonnement abonnement,
    required TarifAbonnement tarif,
  }) async {
    // La formule "par séance" n'est jamais bloquée.
    if (tarif.estParSeance) return;

    final maintenant = DateTime.now();
    final aujourdhui =
    DateTime(maintenant.year, maintenant.month, maintenant.day);

    // Ses paiements pour cette catégorie (musculation, yoga...).
    // Elle lit les anciens paiements de cet adhérent pour cette catégorie.
    final existantes = await _db
        .collection('souscriptions')
        .where('uid', isEqualTo: user.uid)
        .where('abonnementId', isEqualTo: abonnement.id)
        .get();

    for (final doc in existantes.docs) {
      ///Elle récupère la dateFin de chacun, celle qui a été écrite lors d’un paiement précédent
      final dateFin = (doc.data()['dateFin'] as Timestamp?)?.toDate();
      // Encore valable si la date de fin n'est pas passée.
      ///Elle compare cette date avec aujourd’hui
      if (dateFin != null && !dateFin.isBefore(aujourdhui)) {
        final jj = dateFin.day.toString().padLeft(2, '0');
        final mm = dateFin.month.toString().padLeft(2, '0');
        throw AbonnementDejaActif(
          'Vous avez déjà un abonnement « ${abonnement.type} » en cours, '
              'valable jusqu\'au $jj/$mm/${dateFin.year}. Vous pourrez le '
              'renouveler après cette date.',
        );
      }
    }
  }

  //
  // ENREGISTREMENT DU PAIEMENT
  // Renvoie true quand la fiche adhérent existe (trouvée ou créée).
  // Lance AbonnementDejaActif si la même catégorie est encore en cours.
  Future<bool> enregistrer({
    required User user,
    required String nom, // nom affiché : "Prénom NOM"
    required Abonnement abonnement,
    required TarifAbonnement tarif,
    required String numeroCarte, // 16 chiffres, sans espaces
  }) async {
    // 1) VÉRIFICATION de sécurité (déjà faite au clic sur "Souscrire").
    await verifierAbonnementActif(
      user: user,
      abonnement: abonnement,
      tarif: tarif,
    );

    // 2) Retrouver la fiche de l'adhérent grâce à son EMAIL
    //    (la fiche adhérent est liée au compte par l'email).
    final fiche = await _db
        .collection('adherents')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    //  ICI : appeler la vraie passerelle de paiement (Konnect, Flouci...)
    await Future.delayed(const Duration(seconds: 2)); // simulation

    // 3) Dates de la souscription.
    //    Pas de date de fin pour la formule "par séance".
    final debut = DateTime.now();
    final fin = tarif.estParSeance ? null : _ajouterMois(debut, tarif.dureeMois);

    // Deux écritures dans UNE seule opération (batch) :
    // les deux réussissent ensemble, ou aucune n'est faite.
    final batch = _db.batch();

    // a) Historique du paiement (collection "souscriptions")
    batch.set(_db.collection('souscriptions').doc(), {
      'uid': user.uid,
      'email': user.email,
      'nom': nom,
      'abonnementId': abonnement.id,
      'abonnementType': abonnement.type,
      'dureeMois': tarif.dureeMois,
      'dureeLabel': tarif.dureeLabel,
      'prix': tarif.prix,
      'carteFin': numeroCarte.substring(12), // 4 derniers chiffres seulement
      'statut': 'payé',
      'dateDebut': Timestamp.fromDate(debut),
      if (fin != null) 'dateFin': Timestamp.fromDate(fin),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // b) Fiche de l'adhérent (ce que l'admin voit).
    //    Elle ne peut contenir qu'UN abonnement : on y garde celui qui se
    //    termine le plus tard, pour que l'adhérent reste "Actif" tant
    //    qu'un de ses abonnements est valable.
    final infosAbonnement = {
      'abonnementId': abonnement.id,
      'dateDebutAbonnement': Timestamp.fromDate(debut),
      'dureeAbonnementMois': tarif.dureeMois,
    };

    if (fiche.docs.isNotEmpty) {
      final data = fiche.docs.first.data();
      final ancienDebut = (data['dateDebutAbonnement'] as Timestamp?)?.toDate();
      final ancienneDuree = (data['dureeAbonnementMois'] as num?)?.toInt() ?? 1;

      var remplacer = true; // fiche sans abonnement : on remplit
      if (ancienDebut != null && data['abonnementId'] != null) {
        final ancienneFin = _ajouterMois(ancienDebut, ancienneDuree);
        final nouvelleFin = _ajouterMois(debut, tarif.dureeMois);
        remplacer = nouvelleFin.isAfter(ancienneFin);
      }
      if (remplacer) {
        batch.update(fiche.docs.first.reference, infosAbonnement);
      }
    } else {
      // Compte inscrit avant la correction : on crée la fiche manquante.
      // Le nom est coupé en deux : le 1er mot = prénom, le reste = nom.
      final parties = nom.split(' ');
      batch.set(_db.collection('adherents').doc(user.uid), {
        'prenom': parties.first,
        'nom': parties.length > 1 ? parties.sublist(1).join(' ') : '',
        'email': user.email ?? '',
        'telephone': '',
        'actif': true,
        'dateInscription': FieldValue.serverTimestamp(),
        ...infosAbonnement,
      });
    }

    // On envoie les écritures en même temps.
    await batch.commit();
    return true;
  }
}