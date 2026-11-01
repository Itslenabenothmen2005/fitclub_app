import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/coach.dart';
import '../../utils/number_validators.dart';
import '../../utils/validators.dart';
import '../../widgets/admin/form_scaffold.dart';
import '../../widgets/admin/text_area_field.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class CoachFormScreen extends StatefulWidget {
  const CoachFormScreen({super.key, this.coach});

  final Coach? coach;

  @override
  State<CoachFormScreen> createState() => _CoachFormScreenState();
}

class _CoachFormScreenState extends State<CoachFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _store = AdminStore.instance;

  late final _prenomCtrl = TextEditingController(text: widget.coach?.prenom ?? '');
  late final _nomCtrl = TextEditingController(text: widget.coach?.nom ?? '');
  late final _emailCtrl = TextEditingController(text: widget.coach?.email ?? '');
  late final _telCtrl = TextEditingController(text: widget.coach?.telephone ?? '');
  late final _specCtrl =
      TextEditingController(text: widget.coach?.specialites.join(', ') ?? '');
  late final _descCtrl = TextEditingController(text: widget.coach?.description ?? '');

  bool get _isEdit => widget.coach != null;

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _specCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final specialites = _specCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _store.saveCoach(Coach(
      id: widget.coach?.id ?? _store.newId('coach'),
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      specialites: specialites,
      description: _descCtrl.text.trim(),
    ));
    Navigator.of(context).pop(_isEdit ? 'Coach modifié.' : 'Coach ajouté.');
  }

  @override
  Widget build(BuildContext context) {
    return FormScaffold(
      title: _isEdit ? 'Modifier le coach' : 'Nouveau coach',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('* Champs obligatoires',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Prénom',
              controller: _prenomCtrl,
              icon: Icons.person_outline,
              validator: (v) => Validators.name(v, 'Le prénom'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nom',
              controller: _nomCtrl,
              icon: Icons.badge_outlined,
              validator: (v) => Validators.name(v, 'Le nom'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Adresse e-mail',
              hint: 'nom@exemple.com',
              controller: _emailCtrl,
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Téléphone',
              hint: '98 111 222',
              controller: _telCtrl,
              icon: Icons.phone_outlined,
              isRequired: false,
              keyboardType: TextInputType.phone,
              validator: NumberValidators.phone,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Spécialités',
              hint: 'Ex. : Musculation, Cardio',
              controller: _specCtrl,
              icon: Icons.fitness_center,
              validator: (v) => Validators.required(v, 'Au moins une spécialité'),
            ),
            const SizedBox(height: 4),
            Text('Séparez les spécialités par une virgule.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AppTextArea(
              label: 'Description',
              isRequired: false,
              controller: _descCtrl,
              hint: 'Parcours, diplômes, approche...',
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Enregistrer' : 'Ajouter le coach',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}