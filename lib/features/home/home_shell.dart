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
            NavigationDestination(
              icon: item.icon(false),
              selectedIcon: item.icon(true),
              label: item.label,
            ),
        ],
      ),
    );
  }

  List<_NavItem> _navItemsForRole(UserRole role) {
    final base = <_NavItem>[
      _NavItem(
        path: '/plan',
        label: 'Plan',
        iconBuilder: _simpleIcon(Icons.task_alt),
      ),
      _NavItem(
        path: '/journal',
        label: 'Diario',
        iconBuilder: _simpleIcon(Icons.favorite),
      ),
      _NavItem(
        path: '/community',
        label: 'Comunidad',
        iconBuilder: _simpleIcon(Icons.groups),
      ),
      _NavItem(
        path: '/prime',
        label: 'PRIME Coloso',
        iconBuilder: (selected) => _PrimeNavIcon(selected: selected),
      ),
      _NavItem(
        path: '/profile',
        label: 'Perfil',
        iconBuilder: _simpleIcon(Icons.person),
      ),
    ];
    if (role == UserRole.coach) {
      base.insert(
        2,
        _NavItem(
          path: '/coach',
          label: 'Coach',
          iconBuilder: _simpleIcon(Icons.support_agent),
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
  const _NavItem({
    required this.path,
    required this.iconBuilder,
    required this.label,
  });

  final String path;
  final Widget Function(bool selected) iconBuilder;
  final String label;

  Widget icon(bool selected) => iconBuilder(selected);
}

Widget Function(bool selected) _simpleIcon(IconData iconData) {
  return (selected) => Icon(iconData);
}

class _PrimeNavIcon extends StatelessWidget {
  const _PrimeNavIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected ? Icons.workspace_premium : Icons.workspace_premium_outlined,
          color: iconColor,
        ),
        Positioned(
          top: -4,
          right: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'PRIME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
