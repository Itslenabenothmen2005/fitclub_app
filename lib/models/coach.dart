/// Un coach de la salle de sport.
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

  /// Document Firestore -> objet Coach.
  /// L'id n'est pas dans les données : c'est le nom du document.
  /// Chaque champ a une valeur de secours ('' ou []) pour ne jamais planter.
  factory Coach.fromMap(String id, Map<String, dynamic> d) => Coach(
    id: id,
    prenom: d['prenom'] as String? ?? '',
    nom: d['nom'] as String? ?? '',
    email: d['email'] as String? ?? '',
    telephone: d['telephone'] as String? ?? '',
    // Firestore renvoie une liste "dynamic" : on la convertit en List<String>.
    specialites: List<String>.from(d['specialites'] ?? []),
    description: d['description'] as String? ?? '',
  );

  /// Objet Coach -> données à enregistrer dans Firestore (sans l'id).
  Map<String, dynamic> toMap() => {
    'prenom': prenom,
    'nom': nom,
    'email': email,
    'telephone': telephone,
    'specialites': specialites,
    'description': description,
  };
}