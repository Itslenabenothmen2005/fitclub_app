import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/abonnement.dart';
import '../../services/souscription_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/adherent/carte_preview.dart';

// PAGE DE PAIEMENT
//
// - Le nom et l'email viennent du compte connecté (lecture seule).
// - L'adhérent saisit : numéro de carte, date d'expiration, code CVC.
// - Après le paiement, SouscriptionService enregistre dans Firestore
//   (voir services/souscription_service.dart).
class PaiementScreen extends StatefulWidget {
  const PaiementScreen({
    super.key,
    required this.abonnement,
    required this.tarif,
  });

  final Abonnement abonnement; // ex : natation
  final TarifAbonnement tarif; // ex : 3 mois - 180 DT

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = SouscriptionService();

  // Un controller par champ : permet de lire ce que l'adhérent a tapé.
  final _carte = TextEditingController();
  final _expiration = TextEditingController();
  final _cvc = TextEditingController();

  // Utilisateur connecté (source du nom et de l'email).
  final _user = FirebaseAuth.instance.currentUser;

  // true pendant le traitement du paiement (affiche le petit cercle).
  bool _enCours = false;

  // Nom affiché : displayName si disponible, sinon le début de l'email.
  String get _nom {
    final name = _user?.displayName;
    if (name != null && name.isNotEmpty) return name;
    return (_user?.email ?? '').split('@').first;
  }

  @override
  void initState() {
    super.initState();
    // Redessine la carte visuelle à chaque frappe.
    _carte.addListener(_rafraichir);
    _expiration.addListener(_rafraichir);
  }

  void _rafraichir() => setState(() {});

  @override
  void dispose() {
    _carte.dispose();
    _expiration.dispose();
    _cvc.dispose();
    super.dispose();
  }

  // VÉRIFICATIONS DE LA CARTE
  //

  // Algorithme de Luhn : détecte les numéros de carte mal tapés.
  bool _luhnValide(String numero) {
    int somme = 0;
    bool doubler = false;
    for (int i = numero.length - 1; i >= 0; i--) {
      int chiffre = int.parse(numero[i]);
      if (doubler) {
        chiffre *= 2;
        if (chiffre > 9) chiffre -= 9;
      }
      somme += chiffre;
      doubler = !doubler;
    }
    return somme % 10 == 0;
  }

  // Date d'expiration : format MM/AA, mois 01-12, carte non expirée.
  String? _validerExpiration(String? value) {
    final texte = value ?? '';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(texte)) return 'Format MM/AA';
    final mois = int.parse(texte.substring(0, 2));
    final annee = 2000 + int.parse(texte.substring(3, 5));
    if (mois < 1 || mois > 12) return 'Mois invalide';
    // Une carte est valable jusqu'à la fin du mois indiqué.
    final finDeValidite = DateTime(annee, mois + 1, 1);
    if (!finDeValidite.isAfter(DateTime.now())) return 'Carte expirée';
    return null;
  }

  // ---------------------------------------------------------------------------
  // PAIEMENT : l'enregistrement dans Firestore est fait par le service
  // ---------------------------------------------------------------------------
  Future<void> _payer() async {
    // Si un champ est invalide, on s'arrête (les erreurs s'affichent en rouge).
    if (!_formKey.currentState!.validate() || _user == null) return;
    setState(() => _enCours = true);

    try {
      final ficheTrouvee = await _service.enregistrer(
        user: _user,
        nom: _nom,
        abonnement: widget.abonnement,
        tarif: widget.tarif,
        numeroCarte: _carte.text.replaceAll(' ', ''),
      );

      if (!mounted) return;
      Navigator.pop(context); // retour à la liste des abonnements
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ficheTrouvee
                ? 'Paiement réussi ✅ Abonnement ${widget.abonnement.type} '
                '(${widget.tarif.dureeLabel}) activé.'
                : 'Paiement enregistré, mais aucune fiche adhérent n\'a été '
                'trouvée pour ${_user.email}.',
          ),
        ),
      );
    } on AbonnementDejaActif catch (e) {
      // L'adhérent a déjà cet abonnement en cours : on affiche le message
      // (avec la date de fin) sans "Paiement échoué".
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      // Autre erreur (ex : permission-denied) : on réactive le bouton
      // et on affiche le message.
      if (!mounted) return;
      setState(() => _enCours = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Paiement échoué : $e')));
    }
  }

  // ---------------------------------------------------------------------------
  // AFFICHAGE DE LA PAGE
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final prix = widget.tarif.prix ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // La carte visuelle (widgets/adherent/carte_preview.dart)
            CartePreview(
              numero: _carte.text,
              expiration: _expiration.text,
              nom: _nom,
            ),
            const SizedBox(height: 20),

            // Récapitulatif de la commande
            Text(
              '${widget.abonnement.type} · ${widget.tarif.dureeLabel}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Total : ${Formatters.price(prix)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),

            // Nom et email : reçus du compte, lecture seule
            TextFormField(
              initialValue: _nom,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Nom',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _user?.email ?? '',
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Numéro de carte : 16 chiffres + vérification de Luhn
            TextFormField(
              controller: _carte,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // chiffres seulement
                LengthLimitingTextInputFormatter(16),
                _CarteFormatter(), // affiche 1234 5678 9012 3456
              ],
              decoration: const InputDecoration(
                labelText: 'Numéro de carte',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (v) {
                final numero = (v ?? '').replaceAll(' ', '');
                if (numero.length != 16) return 'Entrez les 16 chiffres';
                if (!_luhnValide(numero)) return 'Numéro de carte invalide';
                return null; // OK
              },
            ),
            const SizedBox(height: 12),

            // Date d'expiration et CVC côte à côte
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpirationFormatter(), // 1227 devient 12/27
                    ],
                    decoration: const InputDecoration(
                      labelText: "Date d'expiration",
                      hintText: 'MM/AA',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    validator: _validerExpiration,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvc,
                    keyboardType: TextInputType.number,
                    obscureText: true, // le CVC reste caché
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CVC',
                      hintText: '123',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                    (v ?? '').length == 3 ? null : '3 chiffres',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Bouton payer : désactivé + cercle pendant le traitement
            ElevatedButton(
              onPressed: _enCours ? null : _payer,
              child: _enCours
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : Text('Payer ${Formatters.price(prix)}'),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text(
                  'Paiement sécurisé',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ajoute un espace tous les 4 chiffres : 1234 5678 9012 3456
class _CarteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue ancien,
      TextEditingValue nouveau,
      ) {
    final chiffres = nouveau.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < chiffres.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(chiffres[i]);
    }
    final texte = buffer.toString();
    return TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
  }
}

/// Ajoute le "/" après le mois : 1227 devient 12/27
class _ExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue ancien,
      TextEditingValue nouveau,
      ) {
    final chiffres = nouveau.text.replaceAll('/', '');
    final texte = chiffres.length > 2
        ? '${chiffres.substring(0, 2)}/${chiffres.substring(2)}'
        : chiffres;
    return TextEditingValue(
      text: texte,
      selection: TextSelection.collapsed(offset: texte.length),
    );
  }
}