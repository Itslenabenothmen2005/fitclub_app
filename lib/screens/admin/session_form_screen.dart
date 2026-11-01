import 'package:flutter/material.dart';

import '../../data/admin_store.dart';
import '../../models/seance.dart';
import '../../utils/formatters.dart';
import '../../utils/number_validators.dart';
import '../../widgets/admin/dropdown_field.dart';
import '../../widgets/admin/form_scaffold.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';

class SessionFormScreen extends StatefulWidget {
  const SessionFormScreen({super.key, this.seance});

  final Seance? seance;

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  static const _types = [
    'Musculation',
    'Yoga',
    'CrossFit',
    'Pilates',
    'Boxe',
    'Cardio',
    'Zumba',
  ];

  final _formKey = GlobalKey<FormState>();
  final _store = AdminStore.instance;

  late String? _type = widget.seance?.type;
  late String? _coachId = widget.seance?.coachId;
  late DateTime? _date = widget.seance?.date;
  late TimeOfDay? _time = _parseTime(widget.seance?.heure);

  late final _dateCtrl = TextEditingController(
      text: _date == null ? '' : Formatters.date(_date!));
  late final _timeCtrl = TextEditingController(
      text: _time == null ? '' : Formatters.time(_time!));
  late final _dureeCtrl = TextEditingController(
      text: widget.seance == null ? '' : '${widget.seance!.dureeMinutes}');
  late final _nbMaxCtrl = TextEditingController(
      text: widget.seance == null ? '' : '${widget.seance!.nbMax}');

  bool get _isEdit => widget.seance != null;

  static TimeOfDay? _parseTime(String? heure) {
    if (heure == null) return null;
    final p = heure.split(':');
    if (p.length != 2) return null;
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _dureeCtrl.dispose();
    _nbMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateCtrl.text = Formatters.date(picked);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked == null) return;
    setState(() {
      _time = picked;
      _timeCtrl.text = Formatters.time(picked);
    });
  }

  String? _validateNbMax(String? v) {
    final error = NumberValidators.positiveInt(v, 'Le nombre de places');
    if (error != null) return error;
    final n = int.parse(v!.trim());
    final inscrits = widget.seance?.inscrits ?? 0;
    if (n < inscrits) {
      return 'Il y a déjà $inscrits inscrits : indiquez au moins $inscrits places.';
    }
    return null;
  }

  Widget _pickerField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required VoidCallback onTap,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final d = _date!;
    _store.saveSeance(Seance(
      id: widget.seance?.id ?? _store.newId('seance'),
      type: _type!,
      date: DateTime(d.year, d.month, d.day),
      heure: Formatters.time(_time!),
      dureeMinutes: int.parse(_dureeCtrl.text.trim()),
      nbMax: int.parse(_nbMaxCtrl.text.trim()),
      inscrits: widget.seance?.inscrits ?? 0,
      coachId: _coachId!,
    ));
    Navigator.of(context).pop(_isEdit ? 'Séance modifiée.' : 'Séance ajoutée.');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Modifier la séance' : 'Nouvelle séance';
    final coachs = _store.coachs;

    if (coachs.isEmpty) {
      return FormScaffold(
        title: title,
        child: const ErrorBanner(
          message:
              "Aucun coach n'est disponible. Ajoutez d'abord un coach avant de créer une séance.",
        ),
      );
    }

    return FormScaffold(
      title: title,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('* Champs obligatoires',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Type de séance',
              icon: Icons.fitness_center,
              hint: 'Choisir un type',
              value: _type,
              items: _types,
              itemLabel: (t) => t,
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'Choisissez un type de séance.' : null,
            ),
            const SizedBox(height: 16),
            AppDropdown<String>(
              label: 'Coach',
              icon: Icons.sports_gymnastics,
              hint: 'Choisir un coach',
              value: _coachId,
              items: coachs.map((c) => c.id).toList(),
              itemLabel: (id) => _store.coachById(id)?.nomComplet ?? '',
              onChanged: (v) => setState(() => _coachId = v),
              validator: (v) => v == null ? 'Choisissez un coach.' : null,
            ),
            const SizedBox(height: 16),
            _pickerField(
              label: 'Date',
              controller: _dateCtrl,
              icon: Icons.event,
              hint: 'Choisir une date',
              onTap: _pickDate,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'La date est obligatoire.' : null,
            ),
            const SizedBox(height: 16),
            _pickerField(
              label: 'Heure',
              controller: _timeCtrl,
              icon: Icons.schedule,
              hint: 'Choisir une heure',
              onTap: _pickTime,
              validator: (v) =>
                  (v == null || v.isEmpty) ? "L'heure est obligatoire." : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Durée (en minutes)',
              hint: '60',
              controller: _dureeCtrl,
              icon: Icons.timer_outlined,
              keyboardType: TextInputType.number,
              validator: (v) => NumberValidators.positiveInt(v, 'La durée'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nombre maximal de participants',
              hint: '15',
              controller: _nbMaxCtrl,
              icon: Icons.groups_outlined,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              validator: _validateNbMax,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isEdit ? 'Enregistrer' : 'Ajouter la séance',
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}