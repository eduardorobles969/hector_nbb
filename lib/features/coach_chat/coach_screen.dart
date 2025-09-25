import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/prime_lead.dart';
import '../../data/models/user_role.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import '../prime/prime_lead_providers.dart';
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
              return _ScaffoldedState(
                child: _CoachDashboard(coachUid: myUid),
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

class _CoachDashboard extends ConsumerWidget {
  const _CoachDashboard({required this.coachUid});

  final String coachUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPrimeLeadsProvider);
    final assignedAsync = ref.watch(coachUsersProvider(coachUid));

    if (pendingAsync.isLoading || assignedAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pendingAsync.hasError) {
      return const _ErrorState(
        message:
            'No pudimos cargar las solicitudes PRIME. Actualiza la pantalla o intenta nuevamente en unos minutos.',
      );
    }

    if (assignedAsync.hasError) {
      return const _ErrorState(
        message:
            'No pudimos cargar tus colosos asignados. Actualiza la pantalla o intenta nuevamente en unos minutos.',
      );
    }

    final pending = pendingAsync.value ?? const <PrimeLead>[];
    final assigned = assignedAsync.value ?? const <String>[];

    return _CoachDashboardBody(
      coachUid: coachUid,
      pendingLeads: pending,
      activeUserIds: assigned,
    );
  }
}

class _CoachDashboardBody extends StatelessWidget {
  const _CoachDashboardBody({
    required this.coachUid,
    required this.pendingLeads,
    required this.activeUserIds,
  });

  final String coachUid;
  final List<PrimeLead> pendingLeads;
  final List<String> activeUserIds;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        const _SectionHeader(
          icon: Icons.inbox,
          title: 'Solicitudes PRIME pendientes',
          subtitle:
              'Revisa los datos del coloso y asígnate la cuenta para comenzar el acompañamiento.',
        ),
        const SizedBox(height: 8),
        if (pendingLeads.isEmpty)
          const _CoachInfoCard(
            icon: Icons.hourglass_empty,
            title: 'Sin solicitudes por ahora',
            message:
                'Cuando un coloso envíe la encuesta PRIME aparecerá aquí para que puedas tomarla.',
          )
        else
          ...pendingLeads.map(
            (lead) => _PendingLeadCard(
              key: ValueKey('pending-lead-${lead.uid}-${lead.updatedAt}'),
              coachUid: coachUid,
              lead: lead,
            ),
          ),
        const SizedBox(height: 24),
        const _SectionHeader(
          icon: Icons.support_agent,
          title: 'Colosos PRIME activos',
          subtitle:
              'Ingresa al chat para compartir sus planes, resolver dudas y dejar notas de seguimiento.',
        ),
        const SizedBox(height: 8),
        if (activeUserIds.isEmpty)
          const _CoachInfoCard(
            icon: Icons.pending_actions,
            title: 'Aún sin colosos asignados',
            message:
                'Cuando tomes una solicitud PRIME se creará la relación y podrás escribirles desde aquí.',
          )
        else
          ...activeUserIds.map(
            (uid) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: _MemberTile(
                uid: uid,
                leadingIcon: Icons.person,
                fallbackPrefix: 'Coloso',
                subtitle: 'Abrir chat 1:1',
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoachInfoCard extends StatelessWidget {
  const _CoachInfoCard({
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingLeadCard extends ConsumerStatefulWidget {
  const _PendingLeadCard({
    super.key,
    required this.coachUid,
    required this.lead,
  });

  final String coachUid;
  final PrimeLead lead;

  @override
  ConsumerState<_PendingLeadCard> createState() => _PendingLeadCardState();
}

class _PendingLeadCardState extends ConsumerState<_PendingLeadCard> {
  bool _claiming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lead = widget.lead;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    lead.name.isNotEmpty
                        ? lead.name.substring(0, 1).toUpperCase()
                        : 'C',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name.isNotEmpty
                            ? lead.name
                            : _fallbackName(lead.uid, 'Coloso'),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (lead.phone.isNotEmpty)
                        Text(
                          lead.phone,
                          style: theme.textTheme.bodySmall,
                        ),
                      if (lead.email.isNotEmpty)
                        Text(
                          lead.email,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (lead.goal.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Objetivo principal',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                lead.goal,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            if (lead.message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Mensaje para el coach',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                lead.message,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: _claiming ? null : () => _claimLead(context),
                  icon: const Icon(Icons.check),
                  label: Text(_claiming ? 'Asignando…' : 'Asignarme'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimLead(BuildContext context) async {
    setState(() => _claiming = true);
    try {
      await ref.read(primeLeadRepositoryProvider).claimLead(
            leadUid: widget.lead.uid,
            coachUid: widget.coachUid,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Listo! El coloso fue asignado y ya puedes escribirle desde la sección activa.'),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'No se pudo asignar la solicitud.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Esta solicitud ya fue tomada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error al asignar la solicitud. Intenta de nuevo.')),
      );
    } finally {
      if (mounted) {
        setState(() => _claiming = false);
      }
    }
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
