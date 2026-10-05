enum UserRole {
  adherent,
  coach,
  admin;

  /// Renvoie null si la valeur est inconnue : aucun rôle par défaut.
  static UserRole? fromString(String? value) {
    for (final r in UserRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }

  String get label => switch (this) {
    UserRole.adherent => 'Adhérent',
    UserRole.coach => 'Coach',
    UserRole.admin => 'Administrateur',
  };
}

class UserProfile {
  final String uid;
  final String prenom;
  final String nom;
  final String email;
  final UserRole? role;
  final bool actif;

  const UserProfile({
    required this.uid,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.role,
    required this.actif,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> d) {
    return UserProfile(
      uid: uid,
      prenom: d['prenom'] as String? ?? '',
      nom: d['nom'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: UserRole.fromString(d['role'] as String?),
      actif: d['actif'] as bool? ?? true,
    );
  }
}