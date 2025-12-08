import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/prime_lead.dart';
import '../../data/models/user_role.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import '../prime/prime_lead_providers.dart';
import '../prime/prime_lead_copy.dart';
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
              title: 'Inicia sesiÃ³n para continuar',
              message: 'Necesitas una cuenta activa para hablar con un coach.',
            ),
          );
        }

        final myUid = user.uid;
        final profileAsync = ref.watch(currentUserProfileProvider);

        return profileAsync.when(
          data: (profile) {
            final role = profile?.role ?? UserRole.coloso;

            if (role == UserRole.coach || role == UserRole.admin) {
              return _ScaffoldedState(child: _CoachDashboard(coachUid: myUid));
            }

            if (role == UserRole.colosoPrime) {
              final leadAsync = ref.watch(primeLeadProvider(myUid));
              final coachesAsync = ref.watch(userCoachesProvider(myUid));

              if (leadAsync.isLoading || coachesAsync.isLoading) {
                return const _ScaffoldedState(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (leadAsync.hasError) {
                return const _ScaffoldedState(
                  child: _ErrorState(
                    message:
                        'No pudimos cargar el estado de tu membresÃ­a PRIME. Actualiza la pantalla o intenta nuevamente en unos minutos.',
                  ),
                );
              }

              if (coachesAsync.hasError) {
                return const _ScaffoldedState(
                  child: _ErrorState(
                    message:
                        'No pudimos cargar la lista de coaches asignados. Actualiza la pantalla o intenta nuevamente en unos minutos.',
                  ),
                );
              }

              final lead = leadAsync.asData?.value;
              final coachIds = coachesAsync.value ?? const <String>[];

              return _ScaffoldedState(
                child: _PrimeMemberDashboard(lead: lead, coachIds: coachIds),
              );
            }

            return const _ScaffoldedState(
              child: _EmptyState(
                icon: Icons.lock,
                title: 'Acceso exclusivo PRIME',
                message:
                    'SuscrÃ­bete a PRIME COLOSO para hablar directamente con un coach y desbloquear tus planes personalizados.',
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
          message: 'No pudimos validar tu sesiÃ³n. Intenta nuevamente.',
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
              'Revisa los datos del coloso y asÃ­gnate la cuenta para comenzar el acompaÃ±amiento.',
        ),
        const SizedBox(height: 8),
        if (pendingLeads.isEmpty)
          const _CoachInfoCard(
            icon: Icons.hourglass_empty,
            title: 'Sin solicitudes por ahora',
            message:
                'Cuando un coloso envÃ­e la encuesta PRIME aparecerÃ¡ aquÃ­ para que puedas tomarla.',
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
            title: 'AÃºn sin colosos asignados',
            message:
                'Cuando tomes una solicitud PRIME se crearÃ¡ la relaciÃ³n y podrÃ¡s escribirles desde aquÃ­.',
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
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (lead.phone.isNotEmpty)
                        Text(lead.phone, style: theme.textTheme.bodySmall),
                      if (lead.email.isNotEmpty)
                        Text(lead.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (lead.goal.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Objetivo principal',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
                  label: Text(_claiming ? 'Asignandoâ€¦' : 'Asignarme'),
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
      await ref
          .read(primeLeadRepositoryProvider)
          .claimLead(leadUid: widget.lead.uid, coachUid: widget.coachUid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Â¡Listo! El coloso fue asignado y ya puedes escribirle desde la secciÃ³n activa.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'No se pudo asignar la solicitud.'),
        ),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Esta solicitud ya fue tomada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'OcurriÃ³ un error al asignar la solicitud. Intenta de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _claiming = false);
      }
    }
  }
}

class _PrimeMemberDashboard extends StatelessWidget {
  const _PrimeMemberDashboard({required this.lead, required this.coachIds});

  final PrimeLead? lead;
  final List<String> coachIds;

  @override
  Widget build(BuildContext context) {
    final stage = lead?.stage ?? PrimeLeadStage.pendingAssignment;
    final copy = primeLeadCopyForStage(stage);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _PrimeStatusCard(lead: lead, copy: copy),
        const SizedBox(height: 24),
        Text(
          'Tu equipo de coaches',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (coachIds.isEmpty)
          _CoachInfoCard(
            icon: stage == PrimeLeadStage.coachAssigned
                ? Icons.chat_bubble_outline
                : Icons.support_agent,
            title: stage == PrimeLeadStage.coachAssigned
                ? 'Estamos habilitando tu chat'
                : 'AÃºn sin coach asignado',
            message: copy.emptyCoachHint,
          )
        else
          ...coachIds.map(
            (uid) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: _MemberTile(
                uid: uid,
                leadingIcon: Icons.support_agent,
                fallbackPrefix: 'Coach',
                subtitle: 'Chatea con tu coach 1:1',
              ),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/prime/contact'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Actualizar mis datos PRIME'),
        ),
      ],
    );
  }
}

class _PrimeStatusCard extends StatelessWidget {
  const _PrimeStatusCard({required this.lead, required this.copy});

  final PrimeLead? lead;
  final PrimeLeadCopy copy;

  @override
  Widget build(BuildContext context) {
    final stage = lead?.stage ?? PrimeLeadStage.pendingAssignment;
    final badgeColor = primeLeadStatusColor(stage);
    final leadData = lead;
    final updatedAt =
        leadData?.updatedAt ?? leadData?.submittedAt ?? leadData?.createdAt;
    final formattedDate = updatedAt != null
        ? DateFormat('dd MMM yyyy Â· HH:mm', 'es').format(updatedAt.toLocal())
        : null;

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CoachStatusBadge(text: copy.badge, color: badgeColor),
                if (formattedDate != null)
                  Text(
                    'Actualizado $formattedDate',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.description,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (leadData != null && leadData.goal.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Objetivo compartido',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                leadData.goal,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            if (leadData != null && leadData.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mensaje para el coach',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                leadData.message,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
            ],
            if (leadData == null) ...[
              const SizedBox(height: 16),
              Text(
                'Si necesitas compartir tus datos de nuevo abre la encuesta PRIME desde el botÃ³n inferior.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoachStatusBadge extends StatelessWidget {
  const _CoachStatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
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
      loading: () => 'Cargando informaciÃ³n...',
      error: (_, __) =>
          'No pudimos cargar los detalles, pero puedes abrir el chat.',
    );

    return ListTile(
      leading: CircleAvatar(child: Icon(leadingIcon)),
      title: Text(displayName),
      subtitle: Text(subtitleText),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(otherUid: uid, otherName: displayName),
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
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

String _fallbackName(String uid, String prefix) {
  if (uid.isEmpty) return prefix;
  final shortId = uid.length <= 6 ? uid : '${uid.substring(0, 6)}â€¦';
  return '$prefix $shortId';
}
