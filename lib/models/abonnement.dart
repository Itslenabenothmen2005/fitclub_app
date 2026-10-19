/// Type d'abonnement proposé par la salle (Mensuel, Trimestriel, ...).
class Abonnement {
  final String id;
  final String type;
  final double prix;
  final int dureeMois;
  final String avantages;

  const Abonnement({
    required this.id,
    required this.type,
    required this.prix,
    required this.dureeMois,
    required this.avantages,
  });

  String get dureeLabel => dureeMois == 1 ? '1 mois' : '$dureeMois mois';

  /// Document Firestore -> objet Abonnement.
  factory Abonnement.fromMap(String id, Map<String, dynamic> d) => Abonnement(
    id: id,
    type: d['type'] as String? ?? '',
    // "num" accepte int ET double : Firestore peut renvoyer l'un ou l'autre.
    prix: (d['prix'] as num?)?.toDouble() ?? 0,
    dureeMois: (d['dureeMois'] as num?)?.toInt() ?? 1,
    avantages: d['avantages'] as String? ?? '',
  );

  /// Objet Abonnement -> données à enregistrer dans Firestore.
  Map<String, dynamic> toMap() => {
    'type': type,
    'prix': prix,
    'dureeMois': dureeMois,
    'avantages': avantages,
  };
}