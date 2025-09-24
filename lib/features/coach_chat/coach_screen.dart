import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user_role.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import 'assignments_providers.dart';
import 'chat_screen.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    return authAsync.when(
      data: (user) {
        if (user == null) {
          return const _ScaffoldedState(
            child: _EmptyState(
              icon: Icons.login,
              title: 'Inicia sesión para continuar',
              message: 'Necesitas una cuenta activa para hablar con un coach.',
            ),
          );
        }

        final myUid = user.uid;
        final profileAsync = ref.watch(currentUserProfileProvider);

        return profileAsync.when(
          data: (profile) {
            final role = profile?.role ?? UserRole.coloso;

            if (role == UserRole.coach) {
              final usersAsync = ref.watch(coachUsersProvider(myUid));
              return _ScaffoldedState(
                child: usersAsync.when(
                  data: (users) => _CoachAssignmentsList(userIds: users),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const _ErrorState(
                    message:
                        'No pudimos cargar tus usuarios. Intenta nuevamente en unos minutos.',
                  ),
                ),
              );
            }

            if (role == UserRole.colosoPrime) {
              final coachesAsync = ref.watch(userCoachesProvider(myUid));
              return _ScaffoldedState(
                child: coachesAsync.when(
                  data: (coaches) => _PrimeCoachList(coachIds: coaches),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const _ErrorState(
                    message:
                        'No pudimos cargar a tu coach asignado. Intenta nuevamente en unos minutos.',
                  ),
                ),
              );
            }

            return const _ScaffoldedState(
              child: _EmptyState(
                icon: Icons.lock,
                title: 'Acceso exclusivo PRIME',
                message:
                    'Suscríbete a PRIME COLOSO para hablar directamente con un coach y desbloquear tus planes personalizados.',
                action: _PrimeCtaButton(),
              ),
            );
          },
          loading: () => const _ScaffoldedState(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const _ScaffoldedState(
            child: _ErrorState(
              message: 'No pudimos cargar tu perfil. Intenta nuevamente.',
            ),
          ),
        );
      },
      loading: () => const _ScaffoldedState(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const _ScaffoldedState(
        child: _ErrorState(
          message: 'No pudimos validar tu sesión. Intenta nuevamente.',
        ),
      ),
    );
  }
}

class _ScaffoldedState extends StatelessWidget {
  const _ScaffoldedState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: child,
    );
  }
}

class _PrimeCtaButton extends StatelessWidget {
  const _PrimeCtaButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => context.go('/prime'),
      child: const Text('Conoce PRIME COLOSO'),
    );
  }
}

class _CoachAssignmentsList extends ConsumerWidget {
  const _CoachAssignmentsList({required this.userIds});

  final List<String> userIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userIds.isEmpty) {
      return const _EmptyState(
        icon: Icons.pending_actions,
        title: 'Sin usuarios asignados',
        message:
            'Asigna colosos en Firestore en /assignments/{userUid}/coaches/{coachUid} para comenzar el acompañamiento.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: userIds.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Estos son tus colosos PRIME activos. Abre cada chat para compartir planes, responder dudas y dejar notas sobre su progreso.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }
        final uid = userIds[index - 1];
        return _MemberTile(
          uid: uid,
          leadingIcon: Icons.person,
          fallbackPrefix: 'Coloso',
          subtitle: 'Abrir chat 1:1',
        );
      },
    );
  }
}

class _PrimeCoachList extends ConsumerWidget {
  const _PrimeCoachList({required this.coachIds});

  final List<String> coachIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (coachIds.isEmpty) {
      return const _EmptyState(
        icon: Icons.support_agent,
        title: 'Estamos vinculando a tu coach',
        message:
            'Tu membresía PRIME ya está activa. Apenas asignemos un coach aparecerá aquí para que puedas escribirle de inmediato.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: coachIds.length + 1,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Aquí verás a los coaches que llevan tu membresía. Puedes abrir el chat para compartir avances, dudas o solicitar ajustes en tus planes.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }
        final uid = coachIds[index - 1];
        return _MemberTile(
          uid: uid,
          leadingIcon: Icons.support_agent,
          fallbackPrefix: 'Coach',
          subtitle: 'Chatea con tu coach 1:1',
        );
      },
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const _MemberTile({
    required this.uid,
    required this.leadingIcon,
    required this.fallbackPrefix,
    required this.subtitle,
  });

  final String uid;
  final IconData leadingIcon;
  final String fallbackPrefix;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));
    final displayName = profileAsync.when(
      data: (profile) {
        final rawName = profile?.displayName;
        final name = rawName?.trim();
        if (name != null && name.isNotEmpty) {
          return name;
        }
        return _fallbackName(uid, fallbackPrefix);
      },
      loading: () => _fallbackName(uid, fallbackPrefix),
      error: (_, __) => _fallbackName(uid, fallbackPrefix),
    );

    final subtitleText = profileAsync.when(
      data: (_) => subtitle,
      loading: () => 'Cargando información...',
      error: (_, __) => 'No pudimos cargar los detalles, pero puedes abrir el chat.',
    );

    return ListTile(
      leading: CircleAvatar(child: Icon(leadingIcon)),
      title: Text(displayName),
      subtitle: Text(subtitleText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            otherUid: uid,
            otherName: displayName,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

String _fallbackName(String uid, String prefix) {
  if (uid.isEmpty) return prefix;
  final shortId = uid.length <= 6 ? uid : '${uid.substring(0, 6)}…';
  return '$prefix $shortId';
}
