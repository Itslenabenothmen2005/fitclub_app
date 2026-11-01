import 'package:flutter/material.dart';

import '../config/app_config.dart';

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.onPressed, this.enabled = true});

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppConfig.googleLogoAsset,
            width: 22,
            height: 22,
            // Si le logo n'est pas encore ajouté, l'app ne plante pas.
            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('Continuer avec Google'),
        ],
      ),
    );
  }
}