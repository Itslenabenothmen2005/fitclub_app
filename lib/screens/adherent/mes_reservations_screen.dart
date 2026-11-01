
//Il récupère les ids de tes réservations, garde les séances qui correspondent,
// puis les sépare entre « À venir » et « Passées »
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/seance.dart';
import '../../services/reservation_service.dart';
import '../../widgets/adherent/seance_card.dart';
import '../../widgets/admin/empty_state.dart';

/// Écran : MES réservations (séances à venir + séances passées).
/// (Pas de Scaffold ici : c'est AdherentShell qui fournit la barre verte.)
class MesReservationsScreen extends StatelessWidget {
  const MesReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Identifiant de l'adhérent connecté
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final store = AdminStore.instance; // contient déjà séances et coachs

    // 1er flux : les ids des séances que J'AI réservées
    return StreamBuilder<Set<String>>(
      stream: ReservationService().watchMesReservations(uid),
      builder: (context, resaSnap) {
        // Pendant le chargement : roue qui tourne
        if (resaSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final ids = resaSnap.data ?? <String>{};

        // 2e flux : les séances (se met à jour toute seule)
        return ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            // Mes séances = celles dont l'id est dans mes réservations
            // (si l'admin a supprimé une séance, elle disparaît d'ici)
            final mesSeances =
            store.seances.where((s) => ids.contains(s.id)).toList();

            // On sépare : séances à venir / séances déjà passées
            final aVenir =
            mesSeances.where((s) => !store.estPassee(s)).toList();
            // reversed : la séance passée la plus récente en premier
            final passees =
                mesSeances.where((s) => store.estPassee(s)).toList().reversed;

            // Aucune réservation : message d'aide
            if (mesSeances.isEmpty) {
              return const EmptyState(
                icon: Icons.bookmark_border,
                message: "Vous n'avez aucune réservation.\n"
                    'Réservez une séance depuis le menu.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ----- Section "À venir" -----
                if (aVenir.isNotEmpty) ...[
                  _titre(context, 'À venir (${aVenir.length})'),
                  for (final s in aVenir) _carte(store, s, uid, passee: false),
                ],
                // ----- Section "Passées" -----
                if (passees.isNotEmpty) ...[
                  _titre(context, 'Passées'),
                  for (final s in passees) _carte(store, s, uid, passee: true),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // Titre d'une section ("À venir", "Passées")
  Widget _titre(BuildContext context, String texte) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Text(texte, style: Theme.of(context).textTheme.labelLarge),
    );
  }

  // Une carte de séance + un espace en dessous
  Widget _carte(AdminStore store, Seance s, String uid,
      {required bool passee}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SeanceCard(
        seance: s,
        coachNom: store.coachById(s.coachId)?.nomComplet ?? 'Non assigné',
        dejaReservee: true, // toutes ces séances sont réservées par moi
        adherentId: uid,
        passee: passee, // pour les passées : pas de bouton
      ),
    );
  }
}