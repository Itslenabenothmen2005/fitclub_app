import 'package:cloud_firestore/cloud_firestore.dart';

String _readString(
  Map<String, dynamic> data,
  String field, {
  String defaultValue = '',
}) {
  final value = data[field];
  if (value == null) return defaultValue;
  if (value is String) return value;
  throw FormatException('Le champ "$field" doit être une chaîne.');
}

double? _readDouble(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw FormatException('Le champ "$field" doit être numérique.');
}

int _readInt(
  Map<String, dynamic> data,
  String field, {
  required int defaultValue,
}) {
  final value = data[field];
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  throw FormatException('Le champ "$field" doit être numérique.');
}

Map<String, dynamic> _readMap(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('Un élément de "$field" doit être un objet.');
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value,
  };
}

DateTime? _readDate(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  throw FormatException('Le champ "$field" doit être une date Firestore.');
}

class TarifAbonnement {
  static const int dureeParSeance = 0;

  const TarifAbonnement({
    required this.dureeMois,
    required this.prix,
    this.devise = 'DT',
  });

  final int dureeMois;
  final double? prix;
  final String devise;

  bool get estParSeance => dureeMois == dureeParSeance;

  String get dureeLabel => estParSeance
      ? 'Par séance'
      : dureeMois == 1
      ? '1 mois'
      : '$dureeMois mois';

  factory TarifAbonnement.fromMap(Map<String, dynamic> data) {
    final devise = _readString(data, 'devise', defaultValue: 'DT');
    return TarifAbonnement(
      dureeMois: _readInt(data, 'dureeMois', defaultValue: 1),
      prix: _readDouble(data, 'prix'),
      devise: devise,
    );
  }

  Map<String, dynamic> toMap() => {
    'dureeMois': dureeMois,
    'prix': prix,
    'devise': devise,
  };
}

class HoraireAbonnement {
  const HoraireAbonnement({
    required this.jour,
    required this.heureDebut,
    required this.heureFin,
    this.coachId,
    this.coach,
    this.capacite,
  });

  final String jour;
  final String heureDebut;
  final String heureFin;
  final String? coachId;
  final String? coach;
  final int? capacite;

  factory HoraireAbonnement.fromMap(Map<String, dynamic> data) {
    final coachId = _readString(data, 'coachId');
    final coach = _readString(data, 'coach');
    final capacite = _readInt(data, 'capacite', defaultValue: -1);
    return HoraireAbonnement(
      jour: _readString(data, 'jour'),
      heureDebut: _readString(data, 'heureDebut'),
      heureFin: _readString(data, 'heureFin'),
      coachId: coachId.isEmpty ? null : coachId,
      coach: coach.isEmpty ? null : coach,
      capacite: capacite < 0 ? null : capacite,
    );
  }

  Map<String, dynamic> toMap() => {
    'jour': jour,
    'heureDebut': heureDebut,
    'heureFin': heureFin,
    'coachId': coachId,
    'coach': coach,
    'capacite': capacite,
  };
}

class Abonnement {
  const Abonnement({
    required this.id,
    required this.type,
    required this.prix,
    required this.dureeMois,
    required this.avantages,
    this.description = '',
    this.imageUrl,
    this.imageAsset,
    this.formules = const [],
    this.horaires = const [],
    this.isCategory = false,
    this.isDemoPricing = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// Category name for new documents, legacy plan name for older documents.
  final String type;

  /// Retained for compatibility with existing member references and old docs.
  final double prix;
  final int dureeMois;
  final String avantages;
  final String description;
  final String? imageUrl;
  final String? imageAsset;
  final List<TarifAbonnement> formules;
  final List<HoraireAbonnement> horaires;
  final bool isCategory;
  final bool isDemoPricing;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get dureeLabel => dureeMois == 1 ? '1 mois' : '$dureeMois mois';

  TarifAbonnement? tarifPour(int duree) {
    for (final tarif in formules) {
      if (tarif.dureeMois == duree) return tarif;
    }
    return null;
  }

  List<TarifAbonnement> get tarifsDisponibles =>
      formules.where((tarif) => tarif.prix != null).toList();

  List<TarifAbonnement> get tarifsMensuels => formules
      .where(
        (tarif) =>
            tarif.prix != null &&
            tarif.dureeMois > TarifAbonnement.dureeParSeance,
      )
      .toList();

  factory Abonnement.fromMap(String id, Map<String, dynamic> data) {
    final formulaData = data['formules'];
    final scheduleData = data['horaires'];
    if (formulaData != null && formulaData is! List) {
      throw const FormatException('Le champ "formules" doit être une liste.');
    }
    if (scheduleData != null && scheduleData is! List) {
      throw const FormatException('Le champ "horaires" doit être une liste.');
    }
    final advantages = _readString(data, 'avantages');
    final description = _readString(
      data,
      'description',
      defaultValue: advantages,
    );
    final isCategory = data['isCategory'];
    final isDemoPricing = data['isDemoPricing'];
    if (isCategory != null && isCategory is! bool) {
      throw const FormatException('Le champ "isCategory" doit être booléen.');
    }
    if (isDemoPricing != null && isDemoPricing is! bool) {
      throw const FormatException(
        'Le champ "isDemoPricing" doit être booléen.',
      );
    }

    final formules = <TarifAbonnement>[];
    if (formulaData is List) {
      for (final item in formulaData) {
        formules.add(TarifAbonnement.fromMap(_readMap(item, 'formules')));
      }
    }
    final horaires = <HoraireAbonnement>[];
    if (scheduleData is List) {
      for (final item in scheduleData) {
        horaires.add(HoraireAbonnement.fromMap(_readMap(item, 'horaires')));
      }
    }

    return Abonnement(
      id: id,
      type: _readString(data, 'type'),
      prix: _readDouble(data, 'prix') ?? 0,
      dureeMois: _readInt(data, 'dureeMois', defaultValue: 1),
      avantages: advantages,
      description: description,
      imageUrl: _readString(data, 'imageUrl').isEmpty
          ? null
          : _readString(data, 'imageUrl'),
      imageAsset: _readString(data, 'imageAsset').isEmpty
          ? null
          : _readString(data, 'imageAsset'),
      formules: formules,
      horaires: horaires,
      isCategory: isCategory as bool? ?? false,
      isDemoPricing: isDemoPricing as bool? ?? false,
      createdAt: _readDate(data, 'createdAt'),
      updatedAt: _readDate(data, 'updatedAt'),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'prix': prix,
    'dureeMois': dureeMois,
    'avantages': avantages,
    'description': description,
    'imageUrl': imageUrl,
    'imageAsset': imageAsset,
    'formules': formules.map((tarif) => tarif.toMap()).toList(),
    'horaires': horaires.map((horaire) => horaire.toMap()).toList(),
    'isCategory': isCategory,
    'isDemoPricing': isDemoPricing,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };
}
