import 'package:flutter/material.dart';

import '../../models/seance.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../admin/confirm_dialog.dart'; // NOUVEAU : boîte de confirmation
import '../admin/status_chip.dart';

/// Une carte = une séance. Elle est "Stateful" pour pouvoir afficher
/// une petite roue de chargement pendant la réservation.
class SeanceCard extends StatefulWidget {
  const SeanceCard({
    super.key,
    required this.seance,
    required this.coachNom,
    required this.dejaReservee,
    required this.adherentId,
    this.passee = false, // NOUVEAU : par défaut, la séance n'est pas passée
  });

  final Seance seance;
  final String coachNom;
  final bool dejaReservee; // true si l'adhérent a déjà réservé
  final String adherentId;
  final bool passee; // NOUVEAU : true = séance terminée (aucune action)

  @override
  State<SeanceCard> createState() => _SeanceCardState();
}

class _SeanceCardState extends State<SeanceCard> {
  final _service = ReservationService();
  bool _loading = false;


  // Appelée par Flutter quand la carte reçoit de NOUVELLES informations
  // (ex : la réservation vient d'apparaître dans Firestore).
  @override
  void didUpdateWidget(covariant SeanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'état "réservée" vient de changer, Firestore a confirmé :
    // on arrête la roue tout de suite, sans attendre la fin de la transaction.
    if (oldWidget.dejaReservee != widget.dejaReservee) {
      _loading = false; // pas besoin de setState : l'écran se redessine déjà
    }
  }
  // Petit message en bas de l'écran
  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Appelée quand on appuie sur "Réserver" ou "Annuler"
  Future<void> _onPressed() async {
    if (_loading) return;

    // NOUVEAU : avant d'annuler, on demande confirmation
    if (widget.dejaReservee) {
      final s = widget.seance;
      final ok = await showConfirmDialog(
        context,
        title: 'Annuler cette réservation ?',
        message: '${s.type} du ${Formatters.date(s.date)} à ${s.heure}',
        confirmLabel: 'Confirmer',
      );
      // Si l'utilisateur refuse (ou a quitté l'écran), on s'arrête là
      if (!ok || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      if (widget.dejaReservee) {
        await _service.annuler(
            seanceId: widget.seance.id, adherentId: widget.adherentId);
        _snack('Réservation annulée.');
      } else {
        await _service.reserver(
            seanceId: widget.seance.id, adherentId: widget.adherentId);
        _snack('Séance réservée !');
      }
    } on ReservationFailure catch (e) {
      _snack(e.message); // ex : "Séance complète"
    } catch (e) {
      // Affiche la vraie erreur dans la console (onglet Run d'Android Studio)
      debugPrint('Erreur réservation : $e');
      _snack('Erreur : $e'); // TEMPORAIRE : affiche la vraie erreur    }finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Petite roue de chargement à mettre dans le bouton
  Widget get _roue => const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2));

  @override
  Widget build(BuildContext context) {
    final s = widget.seance;
    final reservee = widget.dejaReservee;
    // Complète seulement si je n'ai pas déjà réservé (sinon je dois pouvoir annuler)
    final complete = s.complete && !reservee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre : le type de séance (Yoga, Cardio...)
          Text(
            s.type,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.date(s.date)} à ${s.heure} · ${s.dureeMinutes} min',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Coach : ${widget.coachNom}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),

          // Étiquette d'état : terminée / réservée / complète / places libres
          if (widget.passee)
            const StatusChip(
              label: 'Séance terminée',
              icon: Icons.history,
              color: StatusChip.neutralColor,
            )
          else if (reservee)
            const StatusChip(
              label: 'Vous êtes inscrit',
              icon: Icons.check_circle_outline,
              color: AppColors.accent,
            )
          else if (complete)
              const StatusChip(
                label: 'Complet',
                icon: Icons.block,
                color: AppColors.error,
              )
            else
              StatusChip(
                // ex : "3 places disponibles" ou "1 place disponible"
                label: '${Formatters.plural(s.placesRestantes, 'place')} '
                    'disponible${s.placesRestantes > 1 ? 's' : ''}',
                icon: Icons.event_seat_outlined,
                color: StatusChip.neutralColor,
              ),

          // NOUVEAU : si la séance est passée, on n'affiche AUCUN bouton.
          if (!widget.passee) ...[
            const SizedBox(height: 12),
            // Bouton : Réserver / Annuler / Complet (désactivé si complet)
            SizedBox(
              width: double.infinity,
              child: reservee
                  ? OutlinedButton(
                onPressed: _loading ? null : _onPressed,
                child: _loading
                    ? _roue
                    : const Text('Annuler ma réservation'),
              )
                  : ElevatedButton(
                // onPressed = null -> bouton désactivé
                onPressed: (complete || _loading) ? null : _onPressed,
                child: _loading
                    ? _roue
                    : Text(complete ? 'Complet' : 'Réserver'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}