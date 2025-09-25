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
  UserRole _lastKnownRole = UserRole.coloso;
  bool _hasResolvedRole = false;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final profileAsync = ref.watch(currentUserProfileProvider);
    profileAsync.when(
      data: (profile) {
        _lastKnownRole = profile?.role ?? UserRole.coloso;
        _hasResolvedRole = true;
      },
      loading: () {},
      error: (_, __) {
        _lastKnownRole = UserRole.coloso;
        _hasResolvedRole = true;
      },
    );

    final role = _lastKnownRole;
    final navItems = _navItemsForRole(role);
    final currentIndex = _indexFromLocation(location, navItems);

    if (_hasResolvedRole &&
        (role == UserRole.coach || role == UserRole.colosoPrime) &&
        location.startsWith('/prime')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/coach');
      });
    }

    if (_hasResolvedRole &&
        role == UserRole.coloso &&
        location.startsWith('/coach')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/prime');
      });
    }

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
    final items = <_NavItem>[
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
        path: '/profile',
        label: 'Perfil',
        iconBuilder: _simpleIcon(Icons.person),
      ),
    ];

    if (role == UserRole.coach || role == UserRole.colosoPrime) {
      items.insert(
        2,
        _NavItem(
          path: '/coach',
          label: 'Coach',
          iconBuilder: _simpleIcon(Icons.support_agent),
        ),
      );
    }

    if (role == UserRole.coloso) {
      items.add(
        _NavItem(
          path: '/prime',
          label: 'Plan',
          iconBuilder: (selected) => _PrimeNavIcon(selected: selected),
        ),
      );
    }

    return items;
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
    final accent = const Color(0xFFD0202A);
    final textColor = selected ? Colors.white : colorScheme.onSurfaceVariant;

    return SizedBox(
      width: 76,
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'PRIME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'COLOSO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
