import 'package:flutter/material.dart';

/// Fiche de détails en bas d'écran (clic sur une carte).
Future<void> showDetailSheet(
  BuildContext context, {
  required String title,
  required Map<String, String> rows,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final theme = Theme.of(ctx).textTheme;
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.headlineMedium?.copyWith(fontSize: 22)),
              const SizedBox(height: 12),
              for (final e in rows.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: theme.bodySmall),
                      Text(e.value, style: theme.bodyLarge),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}