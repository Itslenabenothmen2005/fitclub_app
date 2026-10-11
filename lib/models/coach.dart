class Coach {
  final String id;
  final String prenom;
  final String nom;
  final String email;
  final String telephone;
  final List<String> specialites;
  final String description;

  const Coach({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.telephone,
    required this.specialites,
    required this.description,
  });

  String get nomComplet => '$prenom $nom';
}