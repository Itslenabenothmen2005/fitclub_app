import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/coach.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/admin_item_card.dart';
import '../../widgets/admin/avatars.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../widgets/admin/detail_sheet.dart';
import '../../widgets/admin/empty_state.dart';
import '../../widgets/admin/search_field.dart';
import '../../widgets/admin/status_chip.dart';
import 'coach_form_screen.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({super.key});

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  final _store = AdminStore.instance;
  String _query = '';

  List<Coach> _filtered() {
    final q = _query.trim().toLowerCase();
    final list = _store.coachs.where((c) {
      return q.isEmpty ||
          c.nomComplet.toLowerCase().contains(q) ||
          c.specialites.any((s) => s.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    return list;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Coach? coach]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => CoachFormScreen(coach: coach)),
    );
    if (message != null && mounted) _snack(message);
  }

  Future<void> _delete(Coach c) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer ce coach ?',
      message: '${c.nomComplet} sera supprimé définitivement.',
    );
    if (!ok || !mounted) return;
    final error = _store.deleteCoach(c.id);
    _snack(error ?? 'Coach supprimé.');
  }

  void _showDetails(Coach c) {
    showDetailSheet(
      context,
      title: c.nomComplet,
      rows: {
        'E-mail': c.email,
        'Téléphone': c.telephone.isEmpty ? 'Non renseigné' : c.telephone,
        'Spécialités': c.specialites.join(', '),
        if (c.description.isNotEmpty) 'Description': c.description,
        'Séances animées': '${_store.nbSeancesDuCoach(c.id)}',
      },
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
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Ajouter'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchField(
                  hint: 'Rechercher un coach ou une spécialité',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.sports_gymnastics,
                        message: 'Aucun coach ne correspond à votre recherche.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final c = items[i];
                          return AdminItemCard(
                            leading: InitialsAvatar(
                                text: Formatters.initials(c.prenom, c.nom)),
                            title: c.nomComplet,
                            details: [c.specialites.join(', '), c.email],
                            badge: StatusChip(
                              label: Formatters.plural(
                                  _store.nbSeancesDuCoach(c.id), 'séance'),
                              icon: Icons.event_note_outlined,
                              color: StatusChip.neutralColor,
                            ),
                            onTap: () => _showDetails(c),
                            actions: [
                              ItemAction(
                                  label: 'Modifier',
                                  icon: Icons.edit_outlined,
                                  onTap: () => _openForm(c)),
                              ItemAction(
                                  label: 'Supprimer',
                                  icon: Icons.delete_outline,
                                  destructive: true,
                                  onTap: () => _delete(c)),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}