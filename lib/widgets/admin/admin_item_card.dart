import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ItemAction {
  const ItemAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

/// Carte d'élément de liste (adhérent, coach, séance, abonnement) avec menu d'actions.
class AdminItemCard extends StatelessWidget {
  const AdminItemCard({
    super.key,
    required this.leading,
    required this.title,
    required this.actions,
    this.details = const [],
    this.badge,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final List<String> details;
  final Widget? badge;
  final List<ItemAction> actions;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
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
                    for (final d in details)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(d,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    if (badge != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: badge!,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                tooltip: 'Actions',
                onSelected: (i) => actions[i].onTap(),
                itemBuilder: (_) => [
                  for (var i = 0; i < actions.length; i++)
                    PopupMenuItem<int>(
                      value: i,
                      child: Row(
                        children: [
                          Icon(
                            actions[i].icon,
                            color: actions[i].destructive
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            actions[i].label,
                            style: TextStyle(
                              fontSize: 16,
                              color: actions[i].destructive
                                  ? AppColors.error
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}