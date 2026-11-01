import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/user_profile.dart'; // NOUVEAU : pour UserRole
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';      // NOUVEAU : pour AppColors
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/google_button.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/primary_button.dart';

//avec cinq champs
//La confirmation compare au mot de passe via Validators.confirm
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  // NOUVEAU : rôle choisi par l'utilisateur (adhérent par défaut)
  UserRole _role = UserRole.adherent;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() action, String successMessage) async {
    if (_isLoading) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await action();
      if (success) {
        // Retire Sign Up de la pile : AuthGate affiche l'espace du rôle.
        navigator.popUntil((route) => route.isFirst);
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() {
    // Les champs ne sont pas effacés en cas d'erreur.
    if (!_formKey.currentState!.validate()) return;
    _run(
          () => _authService.signUp(
        prenom: _prenomCtrl.text,
        nom: _nomCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        role: _role, // NOUVEAU : le rôle choisi part vers Firestore
      ),
      'Compte créé avec succès !',
    );
  }

  // NOUVEAU : une ligne de choix de rôle (carte verte quand sélectionnée)
  Widget _roleOption(UserRole value, IconData icon) {
    final selected = _role == value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      // On change le rôle seulement si on n'est pas en train de charger
      onTap: _isLoading ? null : () => setState(() => _role = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // Fond vert clair si sélectionné, blanc sinon
          color: selected
              ? AppColors.primary.withValues(alpha: 0.25)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(value.label,
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            // Le petit rond de sélection
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Créez votre compte', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Rejoignez votre salle de sport et commencez votre parcours.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text('* Champs obligatoires', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
            CustomTextField(
              label: 'Prénom',
              controller: _prenomCtrl,
              icon: Icons.person_outline,
              autofillHints: const [AutofillHints.givenName],
              enabled: !_isLoading,
              validator: (v) => Validators.name(v, 'Le prénom'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nom',
              controller: _nomCtrl,
              icon: Icons.badge_outlined,
              autofillHints: const [AutofillHints.familyName],
              enabled: !_isLoading,
              validator: (v) => Validators.name(v, 'Le nom'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Adresse e-mail',
              hint: 'nom@exemple.com',
              controller: _emailCtrl,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !_isLoading,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mot de passe',
              hint: '${AppConfig.minPasswordLength} caractères minimum',
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              isPassword: true,
              autofillHints: const [AutofillHints.newPassword],
              enabled: !_isLoading,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirmer le mot de passe',
              controller: _confirmCtrl,
              icon: Icons.lock_reset_outlined,
              isPassword: true,
              textInputAction: TextInputAction.done,
              enabled: !_isLoading,
              validator: (v) => Validators.confirm(v, _passwordCtrl.text),
              onSubmitted: (_) => _submit(),
            ),

            // NOUVEAU : choix du rôle (remplace l'ancien texte
            // "Votre compte sera créé en tant qu'adhérent...")
            const SizedBox(height: 16),
            Text("Je m'inscris en tant que :",
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            _roleOption(UserRole.adherent, Icons.person_outline),
            const SizedBox(height: 8),
            _roleOption(UserRole.coach, Icons.sports_gymnastics),

            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Créer mon compte',
                isLoading: _isLoading,
                onPressed: _submit),
            const SizedBox(height: 24),
            const OrDivider(label: 'ou'),
            const SizedBox(height: 16),
            GoogleButton(
              enabled: !_isLoading,
              // NOUVEAU : Google reçoit aussi le rôle choisi
              onPressed: () => _run(
                    () => _authService.signInWithGoogle(role: _role),
                'Connexion réussie !',
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Vous avez déjà un compte ?',
                    style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed:
                  _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}