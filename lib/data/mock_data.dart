import '../models/abonnement.dart';
import '../models/adherent.dart';
import '../models/coach.dart';
import '../models/seance.dart';

/// Données de démonstration (aucun backend). Les dates sont calculées
/// par rapport à aujourd'hui pour que les statuts restent cohérents.
class MockData {
  static const idMensuel = 'ab-mensuel';
  static const idTrimestriel = 'ab-trimestriel';
  static const idSemestriel = 'ab-semestriel';
  static const idAnnuel = 'ab-annuel';

  static DateTime _daysFromToday(int days) {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + days);
  }

  static List<Abonnement> abonnements() => const [
        Abonnement(
          id: idMensuel,
          type: 'Mensuel',
          prix: 50,
          dureeMois: 1,
          avantages: 'Accès illimité à la salle et aux séances collectives.',
        ),
        Abonnement(
          id: idTrimestriel,
          type: 'Trimestriel',
          prix: 135,
          dureeMois: 3,
          avantages: 'Accès illimité, 1 bilan forme offert.',
        ),
        Abonnement(
          id: idSemestriel,
          type: 'Semestriel',
          prix: 250,
          dureeMois: 6,
          avantages: 'Accès illimité, bilan forme et programme personnalisé.',
        ),
        Abonnement(
          id: idAnnuel,
          type: 'Annuel',
          prix: 450,
          dureeMois: 12,
          avantages: 'Meilleur tarif, programme personnalisé et suivi coach.',
        ),
      ];

  static List<Coach> coachs() => const [
        Coach(
          id: 'c1',
          prenom: 'Walid',
          nom: 'Chaabane',
          email: 'walid.chaabane@exemple.com',
          telephone: '98 111 222',
          specialites: ['Musculation', 'Cardio'],
          description: 'Coach diplômé, 8 ans d\'expérience en préparation physique.',
        ),
        Coach(
          id: 'c2',
          prenom: 'Mariem',
          nom: 'Sassi',
          email: 'mariem.sassi@exemple.com',
          telephone: '',
          specialites: ['Yoga', 'Pilates'],
          description: 'Spécialiste du bien-être, de la souplesse et de la respiration.',
        ),
        Coach(
          id: 'c3',
          prenom: 'Hatem',
          nom: 'Dridi',
          email: 'hatem.dridi@exemple.com',
          telephone: '55 333 444',
          specialites: ['CrossFit', 'Boxe'],
          description: '',
        ),
      ];

  static List<Adherent> adherents() => [
        Adherent(
          id: 'adh-1',
          prenom: 'Amine',
          nom: 'Trabelsi',
          email: 'amine.trabelsi@exemple.com',
          telephone: '22 123 456',
          dateInscription: _daysFromToday(-200),
          abonnementId: idAnnuel,
          dateDebutAbonnement: _daysFromToday(-120),
          actif: true,
        ),
        Adherent(
          id: 'adh-2',
          prenom: 'Sarra',
          nom: 'Ben Ali',
          email: 'sarra.benali@exemple.com',
          telephone: '23 456 789',
          dateInscription: _daysFromToday(-90),
          abonnementId: idMensuel,
          dateDebutAbonnement: _daysFromToday(-10),
          actif: true,
        ),
        Adherent(
          id: 'adh-3',
          prenom: 'Youssef',
          nom: 'Jebali',
          email: 'youssef.jebali@exemple.com',
          telephone: '',
          dateInscription: _daysFromToday(-150),
          abonnementId: idMensuel,
          dateDebutAbonnement: _daysFromToday(-75),
          actif: true,
        ),
        Adherent(
          id: 'adh-4',
          prenom: 'Ines',
          nom: 'Mansour',
          email: 'ines.mansour@exemple.com',
          telephone: '24 987 654',
          dateInscription: _daysFromToday(-40),
          abonnementId: idTrimestriel,
          dateDebutAbonnement: _daysFromToday(-30),
          actif: true,
        ),
        Adherent(
          id: 'adh-5',
          prenom: 'Mehdi',
          nom: 'Gharbi',
          email: 'mehdi.gharbi@exemple.com',
          telephone: '',
          dateInscription: _daysFromToday(-5),
          abonnementId: null,
          dateDebutAbonnement: null,
          actif: true,
        ),
        Adherent(
          id: 'adh-6',
          prenom: 'Nour',
          nom: 'Hammami',
          email: 'nour.hammami@exemple.com',
          telephone: '29 555 111',
          dateInscription: _daysFromToday(-260),
          abonnementId: idSemestriel,
          dateDebutAbonnement: _daysFromToday(-200),
          actif: true,
        ),
        Adherent(
          id: 'adh-7',
          prenom: 'Rania',
          nom: 'Khelifi',
          email: 'rania.khelifi@exemple.com',
          telephone: '',
          dateInscription: _daysFromToday(-8),
          abonnementId: idMensuel,
          dateDebutAbonnement: _daysFromToday(-5),
          actif: true,
        ),
        Adherent(
          id: 'adh-8',
          prenom: 'Karim',
          nom: 'Bouzid',
          email: 'karim.bouzid@exemple.com',
          telephone: '27 222 333',
          dateInscription: _daysFromToday(-320),
          abonnementId: idAnnuel,
          dateDebutAbonnement: _daysFromToday(-300),
          actif: false,
        ),
      ];

  static List<Seance> seances() => [
        Seance(id: 's1', type: 'Musculation', date: _daysFromToday(0), heure: '18:00', dureeMinutes: 60, nbMax: 15, inscrits: 12, coachId: 'c1'),
        Seance(id: 's2', type: 'Yoga', date: _daysFromToday(1), heure: '09:00', dureeMinutes: 60, nbMax: 12, inscrits: 12, coachId: 'c2'),
        Seance(id: 's3', type: 'CrossFit', date: _daysFromToday(2), heure: '19:00', dureeMinutes: 45, nbMax: 10, inscrits: 7, coachId: 'c3'),
        Seance(id: 's4', type: 'Pilates', date: _daysFromToday(3), heure: '10:30', dureeMinutes: 50, nbMax: 12, inscrits: 5, coachId: 'c2'),
        Seance(id: 's5', type: 'Boxe', date: _daysFromToday(4), heure: '18:30', dureeMinutes: 60, nbMax: 10, inscrits: 8, coachId: 'c3'),
        Seance(id: 's6', type: 'Cardio', date: _daysFromToday(5), heure: '07:30', dureeMinutes: 45, nbMax: 20, inscrits: 9, coachId: 'c1'),
        Seance(id: 's7', type: 'Yoga', date: _daysFromToday(-2), heure: '09:00', dureeMinutes: 60, nbMax: 12, inscrits: 10, coachId: 'c2'),
        Seance(id: 's8', type: 'Musculation', date: _daysFromToday(7), heure: '17:00', dureeMinutes: 60, nbMax: 15, inscrits: 3, coachId: 'c1'),
      ];
}