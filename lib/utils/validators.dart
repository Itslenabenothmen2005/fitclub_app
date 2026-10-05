import '../config/app_config.dart';

class Validators {
  static String? required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label est obligatoire.';
    return null;
  }

  static String? name(String? v, String label) {
    final r = required(v, label);
    if (r != null) return r;
    if (v!.trim().length < 2) return '$label doit contenir au moins 2 caractères.';
    return null;
  }

  static String? email(String? v) {
    final r = required(v, "L'adresse e-mail");
    if (r != null) return r;
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v!.trim());
    return ok ? null : "Format invalide. Exemple : nom@exemple.com";
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est obligatoire.';
    if (v.length < AppConfig.minPasswordLength) {
      return 'Au moins ${AppConfig.minPasswordLength} caractères sont requis.';
    }
    return null;
  }

  static String? loginPassword(String? v) =>
      (v == null || v.isEmpty) ? 'Le mot de passe est obligatoire.' : null;

  static String? confirm(String? v, String original) {
    if (v == null || v.isEmpty) return 'Veuillez confirmer le mot de passe.';
    if (v != original) return 'Les deux mots de passe ne correspondent pas.';
    return null;
  }
}