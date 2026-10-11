import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin/admin_app_bar.dart';
import '../auth/login_screen.dart';
import 'coaches_screen.dart';
import 'dashboard_screen.dart';
import 'members_screen.dart';
import 'sessions_screen.dart';

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Cadre de l'espace Administrateur : barre verte + menu latéral + pages.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _items = [
    _NavItem('Tableau de bord', Icons.dashboard_outlined),
    _NavItem('Adhérents', Icons.people_outline),
    _NavItem('Coachs', Icons.sports_gymnastics),
    _NavItem('Séances', Icons.event_note_outlined),
    _NavItem('Abonnements', Icons.card_membership_outlined),
  ];

  void _select(int i) {
    setState(() => _index = i);
    Navigator.of(context).pop(); // ferme le menu
  }

  void _logout() {
    // Pour l'instant : simple retour à l'écran Login (pas de vraie session).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _drawerHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 24, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            'Espace Administrateur',
            style: TextStyle(fontSize: 16, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: adminAppBar(_items[_index].label),
      drawer: Drawer(
        child: Column(
          children: [
            _drawerHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  for (var i = 0; i < _items.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        leading: Icon(_items[i].icon),
                        title: Text(_items[i].label,
                            style: const TextStyle(fontSize: 16)),
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
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text('Se déconnecter',
                      style: TextStyle(fontSize: 16, color: AppColors.error)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onTap: _logout,
                ),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          MembersScreen(),
          CoachesScreen(),
          SessionsScreen(),
          _SubscriptionsPlaceholder(),
        ],
      ),
    );
  }
}

class _SubscriptionsPlaceholder extends StatelessWidget {
  const _SubscriptionsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Écran des abonnements indisponible'),
    );
  }
}