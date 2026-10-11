import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/progress_bar_chart.dart';
import '../../widgets/admin/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AdminStore.instance;
    final theme = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final cards = [
          StatCard(
              icon: Icons.people_outline,
              label: 'Adhérents',
              value: '${store.nbAdherents}'),
          StatCard(
              icon: Icons.check_circle_outline,
              label: 'Abonnements actifs',
              value: '${store.nbAbonnementsActifs}'),
          StatCard(
              icon: Icons.error_outline,
              label: 'Abonnements expirés',
              value: '${store.nbAbonnementsExpires}'),
          StatCard(
              icon: Icons.sports_gymnastics,
              label: 'Coachs',
              value: '${store.nbCoachs}'),
          StatCard(
              icon: Icons.event_note_outlined,
              label: 'Séances programmées',
              value: '${store.nbSeancesProgrammees}'),
          StatCard(
              icon: Icons.bookmark_outline,
              label: 'Réservations à venir',
              value: '${store.nbReservations}'),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Bonjour, Administrateur',
                style: theme.headlineMedium?.copyWith(fontSize: 24)),
            const SizedBox(height: 4),
            Text('Voici un aperçu de votre salle de sport.',
                style: theme.bodyMedium),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final c in cards) SizedBox(width: width, child: c),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Réservations à venir par type de séance',
              child: ProgressBarChart(data: store.reservationsParType),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Adhérents par abonnement',
              child: ProgressBarChart(data: store.adherentsParAbonnement),
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Prochaines séances',
              child: _UpcomingSessions(store: store),
            ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _UpcomingSessions extends StatelessWidget {
  const _UpcomingSessions({required this.store});
  final AdminStore store;

  @override
  Widget build(BuildContext context) {
    final upcoming = store.seancesAVenir.take(3).toList();
    if (upcoming.isEmpty) {
      return Text('Aucune séance programmée.',
          style: Theme.of(context).textTheme.bodyMedium);
    }
    return Column(
      children: [
        for (final s in upcoming)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.event, color: AppColors.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${s.type} · ${s.heure}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                        '${Formatters.date(s.date)} · ${store.coachById(s.coachId)?.nomComplet ?? 'Non assigné'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text('${s.inscrits}/${s.nbMax}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}