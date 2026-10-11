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
}