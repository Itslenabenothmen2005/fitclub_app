import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../utils/number_validators.dart';
import '../../utils/validators.dart';
import '../../widgets/admin/form_scaffold.dart';
import '../../widgets/admin/text_area_field.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class SubscriptionFormScreen extends StatefulWidget {
  const SubscriptionFormScreen({super.key, this.abonnement});

  final Abonnement? abonnement;

  @override
  State<SubscriptionFormScreen> createState() => _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = AdminStore.instance;

  late final _typeCtrl = TextEditingController(text: widget.abonnement?.type ?? '');
  late final _prixCtrl = TextEditingController(
      text: widget.abonnement == null
          ? ''
          : Formatters_price(widget.abonnement!.prix));
  late final _dureeCtrl = TextEditingController(
      text: widget.abonnement == null ? '' : '${widget.abonnement!.dureeMois}');
  late final _avantagesCtrl =
      TextEditingController(text: widget.abonnement?.avantages ?? '');

  bool get _isEdit => widget.abonnement != null;

  // Prix sans "DT" pour pouvoir le modifier dans le champ.
  // ignore: non_constant_identifier_names
  static String Formatters_price(double p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(2);

  @override
  void dispose() {
    _typeCtrl.dispose();
    _prixCtrl.dispose();
    _dureeCtrl.dispose();
    _avantagesCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _store.saveAbonnement(Abonnement(
      id: widget.abonnement?.id ?? _store.newId('ab'),
      type: _typeCtrl.text.trim(),
      prix: NumberValidators.parsePrice(_prixCtrl.text)!,
      dureeMois: int.parse(_dureeCtrl.text.trim()),
      avantages: _avantagesCtrl.text.trim(),
    ));
    Navigator.of(context)
        .pop(_isEdit ? 'Abonnement modifié.' : 'Abonnement ajouté.');
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: _isEdit ? "Modifier l'abonnement" : 'Nouvel abonnement',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('* Champs obligatoires',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            CustomTextField(
              label: "Nom de l'abonnement",
              hint: 'Ex. : Mensuel',
              controller: _typeCtrl,
              icon: Icons.card_membership_outlined,
              validator: (v) => Validators.name(v, 'Le nom'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Prix (en DT)',
              hint: '50',
              controller: _prixCtrl,
              icon: Icons.payments_outlined,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => NumberValidators.positivePrice(v, 'Le prix'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Durée (en mois)',
              hint: '1',
              controller: _dureeCtrl,
              icon: Icons.calendar_month_outlined,
              keyboardType: TextInputType.number,
              validator: (v) => NumberValidators.positiveInt(v, 'La durée'),
            ),
            const SizedBox(height: 16),
            AppTextArea(
              label: 'Avantages',
              controller: _avantagesCtrl,
              hint: 'Accès illimité, bilan forme offert...',
              validator: (v) => Validators.required(v, 'Les avantages'),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Enregistrer' : "Ajouter l'abonnement",
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}