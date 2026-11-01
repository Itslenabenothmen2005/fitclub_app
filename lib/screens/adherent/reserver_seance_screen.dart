import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../services/reservation_service.dart';
import '../../widgets/adherent/seance_card.dart'; // la carte est maintenant à part
import '../../widgets/admin/empty_state.dart';

/// Écran : liste des séances à venir + réservation / annulation.
/// (Pas de Scaffold ici : c'est AdherentShell qui fournit la barre verte.)
class ReserverSeanceScreen extends StatelessWidget {
  const ReserverSeanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Identifiant de l'adhérent connecté
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final store = AdminStore.instance; // contient déjà les séances et les coachs

    // 1er flux : MES réservations (pour savoir quel bouton afficher)
    return StreamBuilder<Set<String>>(
      stream: ReservationService().watchMesReservations(uid),
      builder: (context, resaSnap) {
        final mesReservations = resaSnap.data ?? <String>{};

        // 2e flux : les séances (se met à jour toute seule)
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            final seances = store.seancesAVenir; // seulement celles à venir

            if (seances.isEmpty) {
              return const EmptyState(
                icon: Icons.event_busy_outlined,
                message: 'Aucune séance disponible pour le moment.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: seances.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final s = seances[i];
                return SeanceCard(
                  seance: s,
                  coachNom:
                  store.coachById(s.coachId)?.nomComplet ?? 'Non assigné',
                  dejaReservee: mesReservations.contains(s.id),
                  adherentId: uid,
                );
              },
            );
          },
        );
      },
    );
  }
}