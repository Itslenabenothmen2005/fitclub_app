import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/google_button.dart';
import '../../widgets/or_divider.dart';
import '../../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /// Exécute une action d'authentification avec état de chargement.
  Future<void> _run(Future<bool> Function() action) async {
    if (_isLoading) return; // anti double-clic
    // On garde le messenger : l'écran peut être remplacé par AuthGate
    // dès que la connexion réussit.
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final success = await action();
      if (success) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Connexion réussie !')));
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _run(() => _authService.signIn(
        email: _emailCtrl.text, password: _passwordCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Heureux de vous revoir !',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Connectez-vous pour continuer votre parcours fitness.',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 16),
            ],
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
              controller: _passwordCtrl,
              icon: Icons.lock_outline,
              isPassword: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              enabled: !_isLoading,
              validator: Validators.loginPassword,
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ForgotPasswordScreen(
                      initialEmail: _emailCtrl.text.trim()),
                )),
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
                label: 'Se connecter',
                isLoading: _isLoading,
                onPressed: _submit),
            const SizedBox(height: 24),
            const OrDivider(label: 'ou continuer avec'),
            const SizedBox(height: 16),
            GoogleButton(
              enabled: !_isLoading,
              onPressed: () => _run(_authService.signInWithGoogle),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Vous n'avez pas de compte ?",
                    style: theme.textTheme.bodyMedium),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SignUpScreen())),
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}