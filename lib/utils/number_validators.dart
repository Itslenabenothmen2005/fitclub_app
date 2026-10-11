/// Validations numériques utilisées par les formulaires de l'administrateur.
class NumberValidators {
  static String? positiveInt(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label est obligatoire.';
    final n = int.tryParse(v.trim());
    if (n == null || n <= 0) {
      return '$label doit être un nombre entier positif.';
    }
    return null;
  }

  static double? parsePrice(String v) =>
      double.tryParse(v.trim().replaceAll(',', '.'));

  static String? positivePrice(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label est obligatoire.';
    final n = parsePrice(v);
    if (n == null || n <= 0) return '$label doit être un nombre positif.';
    return null;
  }

  /// Téléphone facultatif : 8 chiffres, avec ou sans +216.
  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final ok = RegExp(r'^(\+216)?\s?\d{2}\s?\d{3}\s?\d{3}$').hasMatch(v.trim());
    return ok ? null : 'Numéro invalide. Exemple : 22 123 456';
  }
}