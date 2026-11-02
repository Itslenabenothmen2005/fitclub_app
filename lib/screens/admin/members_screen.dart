import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/adherent.dart';
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
import 'member_form_screen.dart';

enum _MemberFilter {
  tous('Tous'),
  actif('Abonnés actifs'),
  expire('Expirés'),
  aucun('Sans abonnement'),
  desactive('Comptes désactivés');

  const _MemberFilter(this.label);
  final String label;
}

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _store = AdminStore.instance;
  String _query = '';
  _MemberFilter _filter = _MemberFilter.tous;

  List<Adherent> _filtered() {
    final q = _query.trim().toLowerCase();
    final list = _store.adherents.where((a) {
      final matchQuery = q.isEmpty ||
          a.nomComplet.toLowerCase().contains(q) ||
          a.email.toLowerCase().contains(q);
      final statut = _store.statut(a);
      final matchFilter = switch (_filter) {
        _MemberFilter.tous => true,
        _MemberFilter.actif => statut == StatutAbonnement.actif,
        _MemberFilter.expire => statut == StatutAbonnement.expire,
        _MemberFilter.aucun => statut == StatutAbonnement.aucun,
        _MemberFilter.desactive => !a.actif,
      };
      return matchQuery && matchFilter;
    }).toList();
    list.sort((a, b) => a.nomComplet.compareTo(b.nomComplet));
    return list;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Adherent? adherent]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => MemberFormScreen(adherent: adherent)),
    );
    if (message != null && mounted) _snack(message);
  }

  void _toggle(Adherent a) {
    _store.toggleAdherentActif(a.id);
    _snack(a.actif ? 'Compte désactivé.' : 'Compte réactivé.');
  }

  Future<void> _delete(Adherent a) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer cet adhérent ?',
      message: '${a.nomComplet} sera supprimé définitivement.',
    );
    if (!ok || !mounted) return;
    _store.deleteAdherent(a.id);
    _snack('Adhérent supprimé.');
  }

  void _showDetails(Adherent a) {//Fiche de détails au clic
    final plan = _store.abonnementById(a.abonnementId);
    final fin = _store.finAbonnement(a);
    showDetailSheet(
      context,
      title: a.nomComplet,
      rows: {
        'E-mail': a.email,
        'Téléphone': a.telephone.isEmpty ? 'Non renseigné' : a.telephone,
        'Inscrit le': Formatters.date(a.dateInscription),
        'Abonnement': plan == null
            ? 'Aucun'
            : a.dureeAbonnementMois == null
                ? plan.type
                : '${plan.type} · ${a.dureeAbonnementMois} mois',
        if (fin != null) "Date d'expiration": Formatters.date(fin),
        'Statut du compte': a.actif ? 'Actif' : 'Désactivé',
      },
    );
  }

  Color _statutColor(StatutAbonnement s) => switch (s) {
        StatutAbonnement.actif => AppColors.accent,
        StatutAbonnement.expire => AppColors.error,
        StatutAbonnement.aucun => StatusChip.neutralColor,
      };

  Widget _card(Adherent a) {
    final statut = _store.statut(a);
    final plan = _store.abonnementById(a.abonnementId);
    final fin = _store.finAbonnement(a);
    final abonnementText = plan == null
        ? 'Aucun abonnement'
        : fin == null
            ? plan.type
            : "${plan.type}${a.dureeAbonnementMois == null ? '' : ' · ${a.dureeAbonnementMois} mois'} · jusqu'au ${Formatters.date(fin)}";

    return AdminItemCard(
      leading: InitialsAvatar(text: Formatters.initials(a.prenom, a.nom)),
      title: a.nomComplet,
      details: [a.email, abonnementText],
      badge: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          StatusChip(
              label: statut.label,
              icon: statut.icon,
              color: _statutColor(statut)),
          if (!a.actif)
            const StatusChip(
                label: 'Compte désactivé',
                icon: Icons.block,
                color: AppColors.error),
        ],
      ),
      onTap: () => _showDetails(a),
      actions: [//Menu des 3 points :
        ItemAction(
            label: 'Modifier',
            icon: Icons.edit_outlined,
            onTap: () => _openForm(a)),
        ItemAction(
            label: a.actif ? 'Désactiver le compte' : 'Réactiver le compte',
            icon: a.actif ? Icons.person_off_outlined : Icons.person_outline,
            onTap: () => _toggle(a)),
        ItemAction(
            label: 'Supprimer',
            icon: Icons.delete_outline,
            destructive: true,
            onTap: () => _delete(a)),
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
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Ajouter'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SearchField(
                  hint: 'Rechercher un adhérent',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              FilterChipsBar<_MemberFilter>(
                values: _MemberFilter.values,
                selected: _filter,
                labelOf: (f) => f.label,
                onSelected: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        message: 'Aucun adhérent ne correspond à votre recherche.')
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