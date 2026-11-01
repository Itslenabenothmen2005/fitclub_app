import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Graphique à barres horizontales (sans package externe).
class ProgressBarChart extends StatelessWidget {
  const ProgressBarChart({super.key, required this.data});
  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text('Aucune donnée pour le moment.',
          style: Theme.of(context).textTheme.bodyMedium);
    }
    final maxValue = data.values.fold<int>(1, (m, v) => v > m ? v : m);

    return Column(
      children: data.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.key,
                        style: Theme.of(context).textTheme.bodyLarge),
                  ),
                  Text('${e.value}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: e.value / maxValue,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFE5E7EB),
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}