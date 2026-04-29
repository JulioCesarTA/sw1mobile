import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/session_store.dart';
import 'pages/dashboard_page.dart';
import 'pages/tramites_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.session,
    required this.sessionStore,
    required this.onLogout,
  });

  final UserSession session;
  final SessionStore sessionStore;
  final Future<void> Function() onLogout;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = const [
      _NavDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
      ),
      _NavDestination(
        label: 'Seguimiento de tramites',
        icon: Icons.assignment_turned_in_outlined,
      ),
    ];

    final pages = [
      DashboardPage(session: widget.session),
      TramitesPage(session: widget.session),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer = constraints.maxWidth < 900;

        return Scaffold(
          appBar: useDrawer
              ? AppBar(
                  title: Text(destinations[_selectedIndex].label),
                  actions: [_LogoutButton(onLogout: widget.onLogout)],
                )
              : null,
          drawer: useDrawer
              ? Drawer(
                  child: _SidebarContent(
                    user: widget.session.user,
                    destinations: destinations,
                    selectedIndex: _selectedIndex,
                    onSelect: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.of(context).pop();
                    },
                    onLogout: widget.onLogout,
                  ),
                )
              : null,
          body: Row(
            children: [
              if (!useDrawer)
                SizedBox(
                  width: 290,
                  child: _SidebarContent(
                    user: widget.session.user,
                    destinations: destinations,
                    selectedIndex: _selectedIndex,
                    onSelect: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    onLogout: widget.onLogout,
                  ),
                ),
              Expanded(child: pages[_selectedIndex]),
            ],
          ),
        );
      },
    );
  }
}

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.user,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  final AppUser user;
  final List<_NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workflow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role,
                  style: const TextStyle(color: Color(0xFF99F6E4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          for (var index = 0; index < destinations.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                selected: selectedIndex == index,
                selectedTileColor: const Color(0xFF134E4A),
                iconColor: Colors.white70,
                selectedColor: Colors.white,
                textColor: Colors.white70,
                leading: Icon(destinations[index].icon),
                title: Text(destinations[index].label),
                onTap: () => onSelect(index),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesion'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onLogout,
      icon: const Icon(Icons.logout),
      tooltip: 'Cerrar sesion',
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
