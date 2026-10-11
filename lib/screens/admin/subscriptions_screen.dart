import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/admin_item_card.dart';
import '../../widgets/admin/avatars.dart';
import '../../widgets/admin/confirm_dialog.dart';
import '../../widgets/admin/detail_sheet.dart';
import '../../widgets/admin/empty_state.dart';
import '../../widgets/admin/status_chip.dart';
import 'subscription_form_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _store = AdminStore.instance;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openForm([Abonnement? abonnement]) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute(
          builder: (_) => SubscriptionFormScreen(abonnement: abonnement)),
    );
    if (message != null && mounted) _snack(message);
  }

  Future<void> _delete(Abonnement a) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Supprimer cet abonnement ?',
      message: "L'abonnement « ${a.type} » sera supprimé définitivement.",
    );
    if (!ok || !mounted) return;
    final error = _store.deleteAbonnement(a.id);
    _snack(error ?? 'Abonnement supprimé.');
  }

  void _showDetails(Abonnement a) {
    showDetailSheet(
      context,
      title: a.type,
      rows: {
        'Prix': Formatters.price(a.prix),
        'Durée': a.dureeLabel,
        'Avantages': a.avantages,
        'Adhérents concernés': '${_store.nbAdherentsDeLAbonnement(a.id)}',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final items = _store.abonnements;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.primaryDark,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          body: items.isEmpty
              ? const EmptyState(
                  icon: Icons.card_membership_outlined,
                  message: "Aucun abonnement n'est proposé pour le moment.")
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final a = items[i];
                    return AdminItemCard(
                      leading: const IconAvatar(
                          icon: Icons.card_membership_outlined),
                      title: a.type,
                      details: [
                        '${Formatters.price(a.prix)} · ${a.dureeLabel}',
                        a.avantages,
                      ],
                      badge: StatusChip(
                        label: Formatters.plural(
                            _store.nbAdherentsDeLAbonnement(a.id), 'adhérent'),
                        icon: Icons.people_outline,
                        color: StatusChip.neutralColor,
                      ),
                      onTap: () => _showDetails(a),
                      actions: [
                        ItemAction(
                            label: 'Modifier',
                            icon: Icons.edit_outlined,
                            onTap: () => _openForm(a)),
                        ItemAction(
                            label: 'Supprimer',
                            icon: Icons.delete_outline,
                            destructive: true,
                            onTap: () => _delete(a)),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}