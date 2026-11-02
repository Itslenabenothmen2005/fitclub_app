import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/admin_store.dart';
import '../../models/abonnement.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/number_validators.dart';
import '../../utils/validators.dart';
import '../../widgets/admin/dropdown_field.dart';
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
  static const _durations = [TarifAbonnement.dureeParSeance, 1, 3, 6, 12];
  static const _weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  final _formKey = GlobalKey<FormState>();
  final _store = AdminStore.instance;
  final _picker = ImagePicker();
  late final bool _categoryMode = widget.abonnement?.isCategory ?? true;
  late final _nameCtrl = TextEditingController(
    text: widget.abonnement?.type ?? '',
  );
  late final _descriptionCtrl = TextEditingController(
    text: widget.abonnement?.description ?? widget.abonnement?.avantages ?? '',
  );
  late final _additionalInfoCtrl = TextEditingController(
    text: widget.abonnement?.avantages ?? '',
  );
  late final _legacyPriceCtrl = TextEditingController(
    text: widget.abonnement == null || widget.abonnement!.isCategory
        ? ''
        : _priceText(widget.abonnement!.prix),
  );
  late final _legacyDurationCtrl = TextEditingController(
    text: widget.abonnement == null || widget.abonnement!.isCategory
        ? ''
        : '${widget.abonnement!.dureeMois}',
  );
  late final Map<int, TextEditingController> _priceCtrls = {
    for (final duration in _durations)
      duration: TextEditingController(
        text: _priceText(widget.abonnement?.tarifPour(duration)?.prix),
      ),
  };
  late final List<_ScheduleDraft> _schedules = [
    for (final schedule in widget.abonnement?.horaires ?? const [])
      _ScheduleDraft.fromSchedule(schedule),
  ];

  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _isSaving = false;
  bool get _isEdit => widget.abonnement != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _additionalInfoCtrl.dispose();
    _legacyPriceCtrl.dispose();
    _legacyDurationCtrl.dispose();
    for (final controller in _priceCtrls.values) {
      controller.dispose();
    }
    for (final schedule in _schedules) {
      schedule.dispose();
    }
    super.dispose();
  }

  String _priceText(double? price) {
    if (price == null) return '';
    return price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1800,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedImage = image;
        _imageBytes = bytes;
      });
    } on PlatformException catch (error) {
      if (mounted) {
        _snack(
          'Impossible de sélectionner cette image : ${error.message ?? error.code}',
        );
      }
    }
  }

  Future<void> _pickTime(_ScheduleDraft schedule, {required bool start}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start
          ? schedule.start ?? const TimeOfDay(hour: 0, minute: 0)
          : schedule.end ?? const TimeOfDay(hour: 0, minute: 0),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        schedule.start = selected;
      } else {
        schedule.end = selected;
      }
    });
  }

  bool _validSchedules() {
    for (final schedule in _schedules) {
      if (schedule.day == null ||
          schedule.start == null ||
          schedule.end == null) {
        _snack('Renseignez le jour et les deux heures de chaque créneau.');
        return false;
      }
      final startMinutes = schedule.start!.hour * 60 + schedule.start!.minute;
      final endMinutes = schedule.end!.hour * 60 + schedule.end!.minute;
      if (endMinutes <= startMinutes) {
        _snack('L’heure de fin doit être après l’heure de début.');
        return false;
      }
      final capacity = schedule.capacityCtrl.text.trim();
      if (capacity.isNotEmpty &&
          NumberValidators.positiveInt(capacity, 'La capacité') != null) {
        _snack('La capacité doit être un nombre entier positif.');
        return false;
      }
    }
    return true;
  }

  String _contentType(XFile file) {
    final mimeType = file.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryMode && !_validSchedules()) return;
    setState(() => _isSaving = true);
    try {
      final id = widget.abonnement?.id ?? _store.newId('ab');
      var imageUrl = widget.abonnement?.imageUrl;
      var imageAsset = widget.abonnement?.imageAsset;
      if (_selectedImage != null && _imageBytes != null) {
        imageUrl = await _store.uploadAbonnementImage(
          id,
          _imageBytes!,
          contentType: _contentType(_selectedImage!),
        );
        imageAsset = null;
      }

      final description = _descriptionCtrl.text.trim();
      final formulas = _categoryMode
          ? [
              for (final duration in _durations)
                TarifAbonnement(
                  dureeMois: duration,
                  prix: NumberValidators.parsePrice(
                    _priceCtrls[duration]!.text,
                  ),
                ),
            ]
          : const <TarifAbonnement>[];
      final scheduleList = _categoryMode
          ? [
              for (final schedule in _schedules)
                HoraireAbonnement(
                  jour: schedule.day!,
                  heureDebut: Formatters.time(schedule.start!),
                  heureFin: Formatters.time(schedule.end!),
                  coachId: schedule.coachId,
                  coach: schedule.coachId == null
                      ? null
                      : _store.coachById(schedule.coachId!)?.nomComplet ??
                            schedule.coachName,
                  capacite: int.tryParse(schedule.capacityCtrl.text.trim()),
                ),
            ]
          : widget.abonnement?.horaires ?? const <HoraireAbonnement>[];

      await _store.saveAbonnement(
        Abonnement(
          id: id,
          type: _nameCtrl.text.trim(),
          prix: _categoryMode
              ? NumberValidators.parsePrice(_priceCtrls[1]!.text) ?? 0
              : NumberValidators.parsePrice(_legacyPriceCtrl.text)!,
          dureeMois: _categoryMode
              ? 1
              : int.parse(_legacyDurationCtrl.text.trim()),
          avantages: _additionalInfoCtrl.text.trim(),
          description: description,
          imageUrl: imageUrl,
          imageAsset: imageAsset,
          formules: formulas,
          horaires: scheduleList,
          isCategory: _categoryMode,
          createdAt: widget.abonnement?.createdAt,
        ),
      );
      if (!mounted) return;
      Navigator.of(context)
          .pop(_isEdit ? 'Abonnement modifié.' : 'Abonnement ajouté.');
    } on FirebaseException catch (error) {
      if (mounted) {
        _snack(
          "Échec de l’enregistrement Firebase (${error.code}) : ${error.message ?? 'vérifiez votre configuration et vos règles d’accès.'}",
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        _snack(
          'Échec de l’opération sur l’image : ${error.message ?? error.code}',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _imagePreview() {
    final image = _imageBytes != null
        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
        : widget.abonnement?.imageUrl != null
        ? Image.network(
            widget.abonnement!.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _imagePlaceholder(),
          )
        : widget.abonnement?.imageAsset != null
        ? Image.asset(
            widget.abonnement!.imageAsset!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _imagePlaceholder(),
          )
        : _imagePlaceholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(height: 190, width: double.infinity, child: image),
    );
  }

  Widget _imagePlaceholder() => Container(
    color: const Color(0xFFE9F2DB),
    child: const Center(
      child: Icon(Icons.image_outlined, size: 52, color: Color(0xFF4D7C0F)),
    ),
  );

  Widget _buildSchedules() => ListenableBuilder(
    listenable: _store,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Horaires des séances',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: 'Ajouter un horaire',
              onPressed: _isSaving
                  ? null
                  : () => setState(() => _schedules.add(_ScheduleDraft())),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_schedules.isEmpty)
          const Text('Aucun horaire renseigné.')
        else
          for (var index = 0; index < _schedules.length; index++)
            _scheduleCard(_schedules[index], index),
      ],
    ),
  );

  Widget _scheduleCard(_ScheduleDraft schedule, int index) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Créneau ${index + 1}')),
              IconButton(
                tooltip: 'Supprimer cet horaire',
                onPressed: _isSaving
                    ? null
                    : () => setState(() {
                        _schedules.removeAt(index).dispose();
                      }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          AppDropdown<String>(
            label: 'Jour',
            value: schedule.day,
            items: _weekdays,
            itemLabel: (day) => day,
            onChanged: (value) => setState(() => schedule.day = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(schedule, start: true),
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    schedule.start == null
                        ? 'Début'
                        : Formatters.time(schedule.start!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(schedule, start: false),
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    schedule.end == null
                        ? 'Fin'
                        : Formatters.time(schedule.end!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_store.coachs.isEmpty) ...[
            Text(
              "Aucun coach disponible. Ajoutez d'abord un coach dans l’onglet Coachs.",
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (schedule.coachId != null) _missingCoachNotice(schedule),
          ] else
            _coachDropdown(schedule),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Capacité maximale ',
            controller: schedule.capacityCtrl,
            icon: Icons.groups_outlined,
            isRequired: false,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    ),
  );

  Widget _coachDropdown(_ScheduleDraft schedule) {
    final coaches = [..._store.coachs]
      ..sort((first, second) => first.nomComplet.compareTo(second.nomComplet));
    final selectedCoach = schedule.coachId == null
        ? null
        : _store.coachById(schedule.coachId!);
    final selectedCoachIsMissing =
        schedule.coachId != null && selectedCoach == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdown<String>(
          key: ValueKey(
            '${schedule.coachId}:${coaches.map((coach) => coach.id).join(',')}',
          ),
          label: 'Coach responsable ',
          icon: Icons.person_outline,
          isRequired: false,
          value: selectedCoachIsMissing ? null : schedule.coachId ?? '',
          items: ['', for (final coach in coaches) coach.id],
          itemLabel: (id) {
            if (id.isEmpty) return 'Aucun coach';
            final coach = _store.coachById(id);
            if (coach == null) return '';
            final specialties = coach.specialites;
            return specialties.isEmpty
                ? coach.nomComplet
                : '${coach.nomComplet} (${specialties.join(', ')})';
          },
          onChanged: (value) => setState(
            () => schedule.coachId = value == null || value.isEmpty
                ? null
                : value,
          ),
        ),
        if (selectedCoachIsMissing) _missingCoachNotice(schedule),
      ],
    );
  }

  Widget _missingCoachNotice(_ScheduleDraft schedule) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'Coach précédent : ${schedule.coachName ?? schedule.coachId} (introuvable)',
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  @override
  Widget build(BuildContext context) => FormScaffold(
    title: _isEdit ? 'Modifier l’abonnement' : 'Ajouter un abonnement',
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
            label: _categoryMode
                ? 'Nom de la catégorie'
                : "Nom de l'abonnement",
            hint: 'Ex. : pilates',
            controller: _nameCtrl,
            icon: Icons.card_membership_outlined,
            validator: (value) => Validators.name(value, 'Le nom'),
          ),
          const SizedBox(height: 16),
          AppTextArea(
            label: 'Description',
            controller: _descriptionCtrl,
            hint: 'Présentez brièvement cette activité.',
            validator: (value) => Validators.required(value, 'La description'),
          ),
          const SizedBox(height: 16),
          AppTextArea(
            label: 'Informations complémentaires (facultatif)',
            controller: _additionalInfoCtrl,
            hint: 'Conditions, équipements ou avantages inclus.',
          ),
          if (_categoryMode) ...[
            const SizedBox(height: 18),
            Text('Photo', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            _imagePreview(),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _selectedImage == null
                    ? 'Choisir une image'
                    : 'Changer l’image',
              ),
            ),
            const SizedBox(height: 20),
            Text('Tarifs (DT)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final duration in _durations) ...[
              CustomTextField(
                label: duration == TarifAbonnement.dureeParSeance
                    ? 'Prix par séance (DT)'
                    : duration == 1
                    ? 'Prix pour 1 mois (DT)'
                    : 'Prix pour $duration mois (DT)',
                controller: _priceCtrls[duration]!,
                icon: Icons.payments_outlined,
                isRequired: false,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return NumberValidators.positivePrice(value, 'Le prix');
                },
              ),
              const SizedBox(height: 12),
            ],
            _buildSchedules(),
          ] else ...[
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Prix (DT)',
              controller: _legacyPriceCtrl,
              icon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) =>
                  NumberValidators.positivePrice(value, 'Le prix'),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Durée (en mois)',
              controller: _legacyDurationCtrl,
              icon: Icons.calendar_month_outlined,
              keyboardType: TextInputType.number,
              validator: (value) =>
                  NumberValidators.positiveInt(value, 'La durée'),
            ),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: _isSaving
                ? 'Enregistrement...'
                : _isEdit
                ? 'Enregistrer'
                : 'Ajouter l’abonnement',
            isLoading: _isSaving,
            onPressed: () {
              if (!_isSaving) _submit();
            },
          ),
        ],
      ),
    ),
  );
}

class _ScheduleDraft {
  _ScheduleDraft({this.day, this.start, this.end});

  factory _ScheduleDraft.fromSchedule(HoraireAbonnement schedule) {
    TimeOfDay? parseTime(String value) {
      final parts = value.split(':');
      if (parts.length != 2) return null;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return null;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return _ScheduleDraft(
        day: schedule.jour,
        start: parseTime(schedule.heureDebut),
        end: parseTime(schedule.heureFin),
      )
      ..coachId = schedule.coachId
      ..coachName = schedule.coach
      ..capacityCtrl.text = schedule.capacite?.toString() ?? '';
  }

  String? day;
  TimeOfDay? start;
  TimeOfDay? end;
  String? coachId;
  String? coachName;
  final capacityCtrl = TextEditingController();

  void dispose() {
    capacityCtrl.dispose();
  }
}
