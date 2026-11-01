import 'package:flutter/material.dart';

/// Petites fonctions d'affichage (dates, heures, prix, initiales).
class Formatters {
  static String date(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  static String time(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  static String price(double p) {
    final isInt = p == p.roundToDouble();
    return '${isInt ? p.toStringAsFixed(0) : p.toStringAsFixed(2)} DT';
  }

  static String initials(String prenom, String nom) {
    final a = prenom.trim().isEmpty ? '' : prenom.trim()[0];
    final b = nom.trim().isEmpty ? '' : nom.trim()[0];
    final result = (a + b).toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  /// plural(1, 'séance') -> "1 séance" ; plural(3, 'séance') -> "3 séances"
  static String plural(int n, String singular) =>
      n <= 1 ? '$n $singular' : '$n ${singular}s';

  static String _two(int n) => n.toString().padLeft(2, '0');
}