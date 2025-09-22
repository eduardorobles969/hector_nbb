import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../profile/profile_providers.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final role = profileAsync.asData?.value?.role ?? UserRole.coloso;
    final navItems = _navItemsForRole(role);
    final currentIndex = _indexFromLocation(location, navItems);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _go(navItems[index].path),
        destinations: [
          for (final item in navItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }

  List<_NavItem> _navItemsForRole(UserRole role) {
    final base = <_NavItem>[
      const _NavItem(path: '/plan', icon: Icons.task_alt, label: 'Plan'),
      const _NavItem(path: '/journal', icon: Icons.favorite, label: 'Diario'),
      const _NavItem(
        path: '/community',
        icon: Icons.groups,
        label: 'Comunidad',
      ),
      const _NavItem(path: '/profile', icon: Icons.person, label: 'Perfil'),
    ];
    if (role == UserRole.coach) {
      base.insert(
        2,
        const _NavItem(
          path: '/coach',
          icon: Icons.support_agent,
          label: 'Coach',
        ),
      );
    }
    return base;
  }

  int _indexFromLocation(String loc, List<_NavItem> items) {
    final index = items.indexWhere((item) => loc.startsWith(item.path));
    return index >= 0 ? index : 0;
  }

  void _go(String path) {
    context.go(path);
  }
}

class _NavItem {
  const _NavItem({required this.path, required this.icon, required this.label});

  final String path;
  final IconData icon;
  final String label;
}
