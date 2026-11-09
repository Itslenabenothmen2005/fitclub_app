import 'package:flutter/material.dart';
import 'mes_reservations_screen.dart'; // page 2 : mes réservations
import '../../config/app_config.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/adherent/adherent_action.dart'; // une action = nom + icône
import '../../widgets/adherent/bientot_disponible.dart'; // page provisoire
import 'dashboard_screen.dart'; // page 0 : tableau de bord
import 'reserver_seance_screen.dart'; // page 1 : réservation
import 'adherent_abonnements_screen.dart'; // page 6 : abonnements

/// Cadre de l'espace ADHÉRENT : barre verte + menu latéral + pages.
/// C'est le même principe que AdminShell : le cadre reste, et seule
/// la page à l'intérieur change quand on choisit un élément du menu.
class AdherentShell extends StatefulWidget {
  const AdherentShell({super.key, required this.profile});

  // Le profil vient de Firestore (donné par AuthGate)
  final UserProfile? profile;

  @override
  State<AdherentShell> createState() => _AdherentShellState();
}

class _AdherentShellState extends State<AdherentShell> {
  // Numéro de la page affichée (0 = tableau de bord)
  int _index = 0;

  // NOUVEAU : historique des pages déjà visitées.
  // Sert au bouton Retour : on revient à la page d'avant.
  final List<int> _historique = [];

  // Les éléments du MENU. Leur ORDRE doit être exactement le même que
  // celui des pages dans l'IndexedStack plus bas :
  // le 1er élément = la 1re page, le 2e = la 2e page, etc.
  static const _items = [
    AdherentAction('Tableau de bord', Icons.dashboard_outlined),
    AdherentAction('Réserver une séance', Icons.event_available_outlined),
    AdherentAction('Mes réservations', Icons.bookmark_border),
    AdherentAction("Programme d'entraînement", Icons.fitness_center),
    AdherentAction("Historique d'activités", Icons.history),
    AdherentAction('Infos des coachs', Icons.sports_gymnastics),
    AdherentAction('Abonnements', Icons.card_membership_outlined),
    AdherentAction('Notifications', Icons.notifications_none),
    AdherentAction('Chatbot', Icons.chat_bubble_outline),
    AdherentAction('Mon profil', Icons.person_outline),
  ];

  // NOUVEAU : change de page ET mémorise la page quittée.
  void _changerPage(int i) {
    if (i == _index) return; // déjà sur cette page : rien à faire
    setState(() {
      _historique.add(_index); // on retient d'où l'on vient
      _index = i;
    });
  }

  // NOUVEAU : bouton Retour -> page d'avant, ou tableau de bord s'il n'y en a pas.
  void _retour() {
    setState(() {
      _index = _historique.isNotEmpty ? _historique.removeLast() : 0;
    });
  }

  // Choix dans le MENU : on change de page ET on ferme le menu.
  void _select(int i) {
    _changerPage(i); // MODIFIÉ : mémorise la page quittée
    Navigator.of(context).pop(); // ferme le menu latéral
  }

  // Choix depuis le TABLEAU DE BORD : on change de page seulement.
  // (Pas de pop() ici : le menu n'est pas ouvert, et un pop()
  // fermerait l'écran entier.)
  void _goTo(int i) {
    _changerPage(i); // MODIFIÉ : mémorise la page quittée
  }

  // Déconnexion : on prévient Firebase, c'est tout.
  // AuthGate écoute la connexion : dès qu'il n'y a plus personne
  // de connecté, il affiche tout seul l'écran de connexion.
  void _logout() {
    AuthService().signOut();
  }

  // En-tête vert du menu latéral (même style que l'espace admin)
  Widget _drawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      // padding.top : évite que le texte passe sous la barre d'état du téléphone
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo dans un cercle blanc
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(AppConfig.logoIcon,
                size: 32, color: AppColors.primaryDark),
          ),
          SizedBox(height: 12),
          Text(
            AppConfig.appName,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark),
          ),
          Text(
            'Espace Adhérent',
            style: TextStyle(fontSize: 16, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  // NOUVEAU : barre verte du haut avec la flèche de retour.
  // La flèche est visible sur toutes les pages SAUF le tableau de bord (0).
  // Elle remplace l'ancien appBar: adminAppBar(...)
  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryDark,
      // Le ☰ (menu) reste à gauche automatiquement ; le titre vient après.
      titleSpacing: 0,
      title: Row(
        children: [
          // Flèche de retour : seulement si on n'est pas sur le tableau de bord
          if (_index != 0)
            IconButton(
              tooltip: 'Retour',
              icon: const Icon(Icons.arrow_back),
              onPressed: _retour,
            ),
          // Titre : change selon la page affichée
          Expanded(
            child: Padding(
              // petit espace à gauche quand il n'y a pas de flèche
              padding: EdgeInsets.only(left: _index == 0 ? 16 : 0),
              child: Text(
                _items[_index].label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NOUVEAU : PopScope = gère le bouton Retour du TÉLÉPHONE.
    // Sur une autre page que le tableau de bord, il revient en arrière
    // dans l'appli au lieu de la fermer.
    return PopScope(
      canPop: _index == 0, // sur le tableau de bord : comportement normal
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _retour();
      },
      child: Scaffold(
        // Barre verte du haut : son titre change selon la page affichée
        appBar: _appBar(), // MODIFIÉ : remplace adminAppBar(...)

        // ----- Menu latéral (on l'ouvre avec l'icône ☰) -----
        drawer: Drawer(
          child: Column(
            children: [
              _drawerHeader(context),
              // Expanded + ListView : la liste du menu peut défiler
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // On fabrique une ligne de menu pour chaque élément de _items
                    for (var i = 0; i < _items.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: ListTile(
                          leading: Icon(_items[i].icon),
                          title: Text(_items[i].label,
                              style: const TextStyle(fontSize: 16)),
                          // La page actuelle est mise en vert dans le menu
                          selected: i == _index,
                          selectedColor: AppColors.primaryDark,
                          selectedTileColor:
                          AppColors.primary.withValues(alpha: 0.25),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onTap: () => _select(i),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Bouton de déconnexion, toujours en bas du menu
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    leading:
                    const Icon(Icons.logout, color: AppColors.error),
                    title: const Text('Se déconnecter',
                        style:
                        TextStyle(fontSize: 16, color: AppColors.error)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: _logout,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ----- Les pages -----
        // IndexedStack : contient toutes les pages mais n'en affiche qu'UNE,
        // celle dont le numéro est _index.
        // L'ordre est le même que dans _items (voir plus haut).
        // Quand une fonctionnalité est prête, on remplace la ligne
        // "BientotDisponible(...)" par son écran.
        body: IndexedStack(
          index: _index,
          children: [
            // 0 : tableau de bord (on lui donne le profil, le menu et _goTo)
            AdherentDashboardScreen(
              profile: widget.profile,
              items: _items,
              onOpen: _goTo,
            ),
            const ReserverSeanceScreen(), // 1 : FAIT
            const MesReservationsScreen(), // 2 : FAIT
            const BientotDisponible("Programme d'entraînement"), // 3
            const BientotDisponible("Historique d'activités"), // 4
            const BientotDisponible('Infos des coachs'), // 5
            const AdherentAbonnementsScreen(), // 6 : FAIT
            const BientotDisponible('Notifications'), // 7
            const BientotDisponible('Chatbot'), // 8
            const BientotDisponible('Mon profil'), // 9
          ],
        ),
      ),
    );
  }
}