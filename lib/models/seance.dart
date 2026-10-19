import 'package:cloud_firestore/cloud_firestore.dart'; // pour le type Timestamp

class Seance {
  final String id;
  final String type;
  final DateTime date; // jour seulement (minuit)
  final String heure; // format "HH:mm"
  final int dureeMinutes;
  final int nbMax;
  final int inscrits;
  final String coachId;

  const Seance({
    required this.id,
    required this.type,
    required this.date,
    required this.heure,
    required this.dureeMinutes,
    required this.nbMax,
    required this.inscrits,
    required this.coachId,
  });

  bool get complete => inscrits >= nbMax;

  int get placesRestantes => nbMax - inscrits;

  DateTime get dateHeure {
    final p = heure.split(':');
    final h = int.tryParse(p[0]) ?? 0;
    final m = p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  /// Document Firestore -> objet Seance.
  factory Seance.fromMap(String id, Map<String, dynamic> d) => Seance(
    id: id,
    type: d['type'] as String? ?? '',
    // Firestore stocke les dates en "Timestamp" : on convertit en DateTime.
    date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    heure: d['heure'] as String? ?? '00:00',
    dureeMinutes: (d['dureeMinutes'] as num?)?.toInt() ?? 60,
    nbMax: (d['nbMax'] as num?)?.toInt() ?? 0,
    inscrits: (d['inscrits'] as num?)?.toInt() ?? 0,
    coachId: d['coachId'] as String? ?? '',
  );

  /// Objet Seance -> données à enregistrer dans Firestore.
  Map<String, dynamic> toMap() => {
    'type': type,
    'date': Timestamp.fromDate(date), // DateTime -> Timestamp
    'heure': heure,
    'dureeMinutes': dureeMinutes,
    'nbMax': nbMax,
    'inscrits': inscrits,
    'coachId': coachId,
  };
}