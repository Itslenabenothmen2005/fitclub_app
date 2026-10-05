import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/app_theme.dart';

/// Cadre commun de Login, Sign Up et Mot de passe oublié :
/// en-tête vert arrondi (inspiration B) + contenu défilable.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false});

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _Header(showBack: showBack),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.showBack});
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          if (showBack)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Retour',
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.primaryDark),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Icon(AppConfig.logoIcon,
                size: 38, color: AppColors.primaryDark),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: const Text(
              AppConfig.appName,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark),
            ),
          ),
        ],
      ),
    );
  }
}