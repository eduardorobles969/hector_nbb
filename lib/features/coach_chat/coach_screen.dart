import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_role.dart';
import '../profile/profile_providers.dart';
import 'assignments_providers.dart';
import 'chat_providers.dart';
import 'chat_screen.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.read(chatRepoProvider).myUid;
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: profileAsync.when(
        data: (profile) {
          final role = profile?.role ?? UserRole.coloso;
          if (role == UserRole.coach) {
            final usersAsync = ref.watch(coachUsersProvider(myUid));
            return usersAsync.when(
              data: (users) {
                if (users.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.pending_actions,
                    title: 'Sin usuarios asignados',
                    message:
                        'Crea en Firestore: /assignments/{userUid}/coaches/{coachUid} para enlazar colosos.',
                  );
                }
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final uid = users[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Usuario $uid'),
                      subtitle: const Text('Abrir chat 1:1'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUid: uid,
                            otherName: 'Usuario',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          }

          if (role == UserRole.colosoPrime) {
            final coachesAsync = ref.watch(userCoachesProvider(myUid));
            return coachesAsync.when(
              data: (coaches) {
                if (coaches.isEmpty) {
                  return const _EmptyState(
                    icon: Icons.support_agent,
                    title: 'Estamos vinculando a tu coach',
                    message:
                        'Tu membresía PRIME está activa, pero aún no asignamos un coach. Escríbenos para acelerar el emparejamiento.',
                  );
                }
                return ListView.separated(
                  itemCount: coaches.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final uid = coaches[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.support_agent)),
                      title: Text('Coach $uid'),
                      subtitle: const Text('Chatea con tu coach 1:1'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            otherUid: uid,
                            otherName: 'Coach',
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            );
          }

          return const _EmptyState(
            icon: Icons.lock,
            title: 'Acceso exclusivo PRIME',
            message:
                'Suscríbete a PRIME COLOSO para hablar directamente con un coach y desbloquear tus planes personalizados.',
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

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
          ],
        ),
      ),
    );
  }
}
