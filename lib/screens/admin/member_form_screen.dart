import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../models/adherent.dart';
import '../../utils/formatters.dart';
import '../../utils/number_validators.dart';
import '../../utils/validators.dart';
import '../../widgets/admin/dropdown_field.dart';
import '../../widgets/admin/form_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key, this.adherent});

  /// null = création, sinon modification.
  final Adherent? adherent;

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  static const _none = 'none';

  final _formKey = GlobalKey<FormState>();
  final _store = AdminStore.instance;

  late final _prenomCtrl = TextEditingController(
    text: widget.adherent?.prenom ?? '',
  );
  late final _nomCtrl = TextEditingController(text: widget.adherent?.nom ?? '');
  late final _emailCtrl = TextEditingController(
    text: widget.adherent?.email ?? '',
  );
  late final _telCtrl = TextEditingController(
    text: widget.adherent?.telephone ?? '',
  );
  late DateTime? _dateDebut = widget.adherent?.dateDebutAbonnement;
  late final _dateCtrl = TextEditingController(
    text: _dateDebut == null ? '' : Formatters.date(_dateDebut!),
  );
  late String _abonnementId = widget.adherent?.abonnementId ?? _none;
  late int? _dureeAbonnementMois = widget.adherent?.dureeAbonnementMois;

  bool get _isEdit => widget.adherent != null;

  @override
  void initState() {
    super.initState();
    final plan = _store.abonnementById(_abonnementId);
    final tariffs = _tariffsFor(plan);
    if (_dureeAbonnementMois == null && tariffs.isNotEmpty) {
      _dureeAbonnementMois = tariffs.first.dureeMois;
    }
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateDebut ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _dateDebut = picked;
      _dateCtrl.text = Formatters.date(picked);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final hasPlan = _abonnementId != _none;
    _store.saveAdherent(
      Adherent(
        id: widget.adherent?.id ?? _store.newId('adh'),
        prenom: _prenomCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telephone: _telCtrl.text.trim(),
        dateInscription: widget.adherent?.dateInscription ?? DateTime.now(),
        abonnementId: hasPlan ? _abonnementId : null,
        dureeAbonnementMois: hasPlan ? _dureeAbonnementMois : null,
        dateDebutAbonnement: hasPlan ? _dateDebut : null,
        actif: widget.adherent?.actif ?? true,
      ),
    );
    Navigator.of(context)
        .pop(_isEdit ? 'Adhérent modifié.' : 'Adhérent ajouté.');
  }

  @override
  Widget build(BuildContext context) {
    final plans = _store.abonnements;
    final hasPlan = _abonnementId != _none;
    final selectedPlan = hasPlan ? _store.abonnementById(_abonnementId) : null;
    final availableTariffs = _tariffsFor(selectedPlan);
    final selectedDuration =
        availableTariffs.any(
          (tariff) => tariff.dureeMois == _dureeAbonnementMois,
        )
        ? _dureeAbonnementMois
        : null;

    return FormScaffold(
      title: _isEdit ? "Modifier l'adhérent" : 'Nouvel adhérent',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '* Champs obligatoires',
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
              hint: '22 123 456',
              controller: _telCtrl,
              icon: Icons.phone_outlined,
              isRequired: false,
              keyboardType: TextInputType.phone,
              validator: NumberValidators.phone,
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Abonnement',
              isRequired: false,
              icon: Icons.card_membership_outlined,
              value: _abonnementId,
              items: [_none, ...plans.map((p) => p.id)],
              itemLabel: (id) => id == _none
                  ? 'Aucun abonnement'
                  : _store.abonnementById(id)?.type ?? '',
              onChanged: (v) => setState(() {
                _abonnementId = v ?? _none;
                final tariffs = _tariffsFor(
                  _store.abonnementById(_abonnementId),
                );
                _dureeAbonnementMois = tariffs.isEmpty
                    ? null
                    : tariffs.first.dureeMois;
              }),
            ),
            if (hasPlan) ...[
              const SizedBox(height: 16),
              AppDropdown<int>(
                label: 'Durée de l’abonnement',
                icon: Icons.calendar_month_outlined,
                value: selectedDuration,
                items: availableTariffs
                    .map((tariff) => tariff.dureeMois)
                    .toList(),
                itemLabel: (months) {
                  final tariff = availableTariffs.firstWhere(
                    (item) => item.dureeMois == months,
                  );
                  return '${tariff.dureeLabel} · ${Formatters.price(tariff.prix ?? 0)}';
                },
                validator: (value) => value == null
                    ? 'Aucune durée tarifée disponible pour cet abonnement.'
                    : null,
                onChanged: (value) =>
                    setState(() => _dureeAbonnementMois = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _pickDate,
                validator: (v) => (v == null || v.isEmpty)
                    ? 'La date de début est obligatoire.'
                    : null,
                decoration: const InputDecoration(
                  labelText: "Date de début de l'abonnement",
                  hintText: 'Choisir une date',
                  prefixIcon: Icon(Icons.event),
                ),
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Enregistrer' : "Ajouter l'adhérent",
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  List<TarifAbonnement> _tariffsFor(Abonnement? plan) {
    if (plan == null) return const [];
    if (plan.isCategory) return plan.tarifsMensuels;
    return [TarifAbonnement(dureeMois: plan.dureeMois, prix: plan.prix)];
  }
}
