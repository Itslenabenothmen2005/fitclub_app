import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/seance.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/admin_item_card.dart';
import '../../widgets/admin/avatars.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../widgets/admin/detail_sheet.dart';
import '../../widgets/admin/empty_state.dart';
import '../../widgets/admin/filter_chips_bar.dart';
import '../../widgets/admin/search_field.dart';
import '../../widgets/admin/status_chip.dart';
import 'session_form_screen.dart';

enum _SeanceFilter {
  avenir('À venir'),
  passees('Passées'),
  toutes('Toutes');

  const _SeanceFilter(this.label);
  final String label;
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _store = AdminStore.instance;
  String _query = '';
  _SeanceFilter _filter = _SeanceFilter.avenir;

  String _coachName(Seance s) =>
      _store.coachById(s.coachId)?.nomComplet ?? 'Non assigné';

  List<Seance> _filtered() {
    final q = _query.trim().toLowerCase();
    return _store.seances.where((s) {
      final past = _store.estPassee(s);
      final matchFilter = switch (_filter) {
        _SeanceFilter.avenir => !past,
        _SeanceFilter.passees => past,
        _SeanceFilter.toutes => true,
      };
      final matchQuery = q.isEmpty ||
          s.type.toLowerCase().contains(q) ||
          _coachName(s).toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Seance? seance]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => SessionFormScreen(seance: seance)),
    );
    if (message != null && mounted) _snack(message);
  }

  Future<void> _delete(Seance s) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer cette séance ?',
      message:
          '${s.type} du ${Formatters.date(s.date)} à ${s.heure} sera supprimée définitivement.',
    );
    if (!ok || !mounted) return;
    _store.deleteSeance(s.id);
    _snack('Séance supprimée.');
  }

  void _showDetails(Seance s) {
    showDetailSheet(
      context,
      title: s.type,
      rows: {
        'Date': Formatters.date(s.date),
        'Heure': s.heure,
        'Durée': '${s.dureeMinutes} minutes',
        'Coach': _coachName(s),
        'Inscrits': '${s.inscrits} sur ${s.nbMax} places',
        'Places restantes': '${s.placesRestantes < 0 ? 0 : s.placesRestantes}',
      },
    );
  }

  Widget _card(Seance s) {
    final past = _store.estPassee(s);
    return AdminItemCard(
      leading: const IconAvatar(icon: Icons.fitness_center),
      title: s.type,
      details: [
        '${Formatters.date(s.date)} · ${s.heure} · ${s.dureeMinutes} min',
        'Coach : ${_coachName(s)}',
      ],
      badge: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          StatusChip(
            label: '${s.inscrits}/${s.nbMax} inscrits',
            icon: Icons.groups_outlined,
            color: s.complete ? AppColors.error : AppColors.accent,
          ),
          if (s.complete && !past)
            const StatusChip(
                label: 'Complète', icon: Icons.block, color: AppColors.error),
          if (past)
            const StatusChip(
                label: 'Terminée',
                icon: Icons.history,
                color: StatusChip.neutralColor),
        ],
      ),
      onTap: () => _showDetails(s),
      actions: [
        ItemAction(
            label: 'Modifier',
            icon: Icons.edit_outlined,
            onTap: () => _openForm(s)),
        ItemAction(
            label: 'Supprimer',
            icon: Icons.delete_outline,
            destructive: true,
            onTap: () => _delete(s)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final items = _filtered();
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryDark,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchField(
                  hint: 'Rechercher une séance ou un coach',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              FilterChipsBar<_SeanceFilter>(
                values: _SeanceFilter.values,
                selected: _filter,
                labelOf: (f) => f.label,
                onSelected: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.event_busy_outlined,
                        message: 'Aucune séance ne correspond à votre recherche.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _card(items[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}