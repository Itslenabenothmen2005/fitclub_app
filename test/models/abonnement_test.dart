import 'package:fitclub/models/abonnement.dart';
import 'package:fitclub/models/adherent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Abonnement Firestore compatibility', () {
    test('reads a legacy single-duration document unchanged', () {
      final abonnement = Abonnement.fromMap('legacy-1', {
        'type': 'Mensuel',
        'prix': 45,
        'dureeMois': 1,
        'avantages': 'Accès aux équipements',
      });

      expect(abonnement.id, 'legacy-1');
      expect(abonnement.type, 'Mensuel');
      expect(abonnement.prix, 45);
      expect(abonnement.dureeMois, 1);
      expect(abonnement.isCategory, isFalse);
      expect(abonnement.formules, isEmpty);
    });

    test('round-trips category prices, schedules and image fields', () {
      final abonnement = Abonnement(
        id: 'category-yoga',
        type: 'yoga',
        prix: 0,
        dureeMois: 1,
        avantages: 'Souplesse et équilibre',
        description: 'Souplesse et équilibre',
        imageAsset: 'assets/yoga.png',
        formules: const [
          TarifAbonnement(dureeMois: 1, prix: 40),
          TarifAbonnement(dureeMois: 3, prix: null),
          TarifAbonnement(dureeMois: 6, prix: 200),
          TarifAbonnement(dureeMois: 12, prix: 360),
        ],
        horaires: const [
          HoraireAbonnement(
            jour: 'Lundi',
            heureDebut: '09:00',
            heureFin: '10:00',
            coach: 'Nadia',
            capacite: 12,
          ),
        ],
        isCategory: true,
      );

      final restored = Abonnement.fromMap(abonnement.id, abonnement.toMap());

      expect(restored.isCategory, isTrue);
      expect(restored.formules.map((tarif) => tarif.dureeMois), [1, 3, 6, 12]);
      expect(restored.tarifPour(3)?.prix, isNull);
      expect(restored.tarifPour(6)?.prix, 200);
      expect(restored.imageAsset, 'assets/yoga.png');
      expect(restored.horaires.single.jour, 'Lundi');
      expect(restored.horaires.single.capacite, 12);
    });

    test('round-trips session and monthly category tariffs', () {
      final abonnement = Abonnement(
        id: 'category-yoga',
        type: 'yoga',
        prix: 40,
        dureeMois: 1,
        avantages: 'Souplesse et équilibre',
        formules: const [
          TarifAbonnement(dureeMois: TarifAbonnement.dureeParSeance, prix: 20),
          TarifAbonnement(dureeMois: 1, prix: 40),
          TarifAbonnement(dureeMois: 3, prix: 110),
          TarifAbonnement(dureeMois: 6, prix: 200),
          TarifAbonnement(dureeMois: 12, prix: 360),
        ],
        isCategory: true,
      );

      final restored = Abonnement.fromMap(abonnement.id, abonnement.toMap());
      final sessionTariff = restored.tarifPour(TarifAbonnement.dureeParSeance);

      expect(restored.formules.map((tarif) => tarif.dureeMois), [
        0,
        1,
        3,
        6,
        12,
      ]);
      expect(sessionTariff?.estParSeance, isTrue);
      expect(sessionTariff?.dureeLabel, 'Par séance');
    });

    test('excludes the session tariff from monthly tariffs', () {
      final abonnement = Abonnement(
        id: 'category-pilates',
        type: 'pilates',
        prix: 80,
        dureeMois: 1,
        avantages: '',
        formules: const [
          TarifAbonnement(dureeMois: TarifAbonnement.dureeParSeance, prix: 20),
          TarifAbonnement(dureeMois: 1, prix: 80),
          TarifAbonnement(dureeMois: 3, prix: 210),
          TarifAbonnement(dureeMois: 6, prix: 390),
          TarifAbonnement(dureeMois: 12, prix: 720),
        ],
        isCategory: true,
      );

      expect(abonnement.tarifsMensuels.map((tarif) => tarif.dureeMois), [
        1,
        3,
        6,
        12,
      ]);
    });

    test('reads a legacy category without a session tariff', () {
      final abonnement = Abonnement.fromMap('legacy-category', {
        'type': 'yoga',
        'prix': 40,
        'dureeMois': 1,
        'avantages': '',
        'isCategory': true,
        'formules': [
          {'dureeMois': 1, 'prix': 40},
          {'dureeMois': 3, 'prix': 110},
          {'dureeMois': 6, 'prix': 200},
          {'dureeMois': 12, 'prix': 360},
        ],
      });

      expect(abonnement.tarifPour(TarifAbonnement.dureeParSeance), isNull);
      expect(abonnement.tarifsMensuels.map((tarif) => tarif.dureeMois), [
        1,
        3,
        6,
        12,
      ]);
    });

    test('round-trips a schedule coach id and copied name', () {
      const schedule = HoraireAbonnement(
        jour: 'Mardi',
        heureDebut: '18:00',
        heureFin: '19:00',
        coachId: 'coach-1',
        coach: 'Nadia Ben Ali',
      );

      final restored = HoraireAbonnement.fromMap(schedule.toMap());

      expect(restored.coachId, 'coach-1');
      expect(restored.coach, 'Nadia Ben Ali');
    });

    test('reads a legacy schedule with a free-text coach and no coach id', () {
      final schedule = HoraireAbonnement.fromMap({
        'jour': 'Mardi',
        'heureDebut': '18:00',
        'heureFin': '19:00',
        'coach': 'Nadia Ben Ali',
      });

      expect(schedule.coachId, isNull);
      expect(schedule.coach, 'Nadia Ben Ali');
    });

    test(
      'reports malformed Firestore fields with the offending field name',
      () {
        expect(
          () => Abonnement.fromMap('broken-category', {
            'type': 'yoga',
            'prix': '75 DT',
            'dureeMois': 1,
            'formules': const [],
            'horaires': const [],
          }),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('"prix"'),
            ),
          ),
        );
      },
    );
  });

  test('preserves a member-selected duration in Firestore data', () {
    final adherent = Adherent(
      id: 'member-1',
      prenom: 'Lina',
      nom: 'Ben Ali',
      email: 'lina@example.com',
      telephone: '',
      dateInscription: DateTime(2026, 1, 1),
      abonnementId: 'category-yoga',
      dureeAbonnementMois: 6,
      dateDebutAbonnement: DateTime(2026, 1, 2),
      actif: true,
    );

    final restored = Adherent.fromMap(adherent.id, adherent.toMap());

    expect(restored.abonnementId, 'category-yoga');
    expect(restored.dureeAbonnementMois, 6);
  });
}
