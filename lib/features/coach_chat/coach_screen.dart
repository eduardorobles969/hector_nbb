import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assignments_providers.dart';
import 'chat_providers.dart';
import 'chat_screen.dart';

class CoachScreen extends ConsumerWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.read(chatRepoProvider).myUid; // este dispositivo actua como coach
    final usersAsync = ref.watch(coachUsersProvider(myUid));

    return Scaffold(
      appBar: AppBar(title: const Text('Coach - Usuarios asignados')),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Aun no tienes usuarios asignados.\n'
                  'Crea en Firestore: /assignments/{userUid}/coaches/{coachUid}',
                  textAlign: TextAlign.center,
                ),
              ),
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
      ),
    );
  }
}
