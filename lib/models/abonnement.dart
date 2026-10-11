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
}