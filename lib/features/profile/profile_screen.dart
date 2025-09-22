import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../auth/auth_providers.dart';
import '../../data/models/user_role.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) {
        if (user == null) {
          return const _StatusMessage(
            message: 'Sesion cerrada. Inicia sesion nuevamente.',
          );
        }
        final profileAsync = ref.watch(currentUserProfileProvider);
        final profile = profileAsync.asData?.value;
        final membership = profile?.role ?? UserRole.coloso;
        final displayNameCandidate = (profile?.displayName ?? '').trim();
        final baseName = displayNameCandidate.isNotEmpty
            ? displayNameCandidate
            : (user.displayName?.trim().isNotEmpty ?? false)
            ? user.displayName!.trim()
            : (user.email != null
                  ? user.email!.split('@').first
                  : 'Atleta NBB');
        final email = (profile?.email ?? '').isNotEmpty
            ? profile!.email
            : user.email ?? 'Sin correo';
        final initials = _initialsFrom(baseName);
        final creation = user.metadata.creationTime;
        final lastLogin = user.metadata.lastSignInTime;
        final formatter = DateFormat('dd/MM/yyyy HH:mm');

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050505), Color(0xFF111111)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    initials: initials,
                    name: baseName,
                    email: email,
                    roleLabel: membership.label,
                  ),
                  const SizedBox(height: 28),
                  _InfoCard(
                    title: 'Actividad de la cuenta',
                    children: [
                      _InfoRow(
                        label: 'Creada el',
                        value: creation != null
                            ? formatter.format(creation.toLocal())
                            : 'No disponible',
                      ),
                      _InfoRow(
                        label: 'Ultimo acceso',
                        value: lastLogin != null
                            ? formatter.format(lastLogin.toLocal())
                            : 'No disponible',
                      ),
                      _InfoRow(label: 'UID', value: user.uid, isMono: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoCard(
                    title: 'Preferencias',
                    children: const [
                      _InfoRow(
                        label: 'Modo oscuro',
                        value: 'Automatico segun el sistema',
                      ),
                      _InfoRow(
                        label: 'Notificaciones',
                        value: 'Personaliza desde ajustes proximamente',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _MembershipCard(
                    role: membership,
                    active: profile?.active ?? true,
                  ),

                  if (profile != null && profile.onboardingComplete)
                    _InfoCard(
                      title: 'Datos de batalla',
                      children: [
                        if (profile.fitnessLevel != null &&
                            profile.fitnessLevel!.isNotEmpty)
                          _InfoRow(
                            label: 'Nivel',
                            value: profile.fitnessLevel!,
                          ),
                        if (profile.goals.isNotEmpty)
                          _InfoRow(
                            label: 'Objetivos',
                            value: profile.goals
                                .map((g) => g.replaceAll('_', ' '))
                                .join(', '),
                          ),
                        if (profile.gender != null)
                          _InfoRow(label: 'Genero', value: profile.gender!),
                        if (profile.heightCm != null)
                          _InfoRow(
                            label: 'Estatura',
                            value: '${profile.heightCm} cm',
                          ),
                        if (profile.weightKg != null)
                          _InfoRow(
                            label: 'Peso',
                            value: '${profile.weightKg} kg',
                          ),
                        if (profile.pullupsRange != null)
                          _InfoRow(
                            label: 'Dominadas',
                            value: profile.pullupsRange!,
                          ),
                        if (profile.pushupsRange != null)
                          _InfoRow(
                            label: 'Lagartijas',
                            value: profile.pushupsRange!,
                          ),
                        if (profile.squatsRange != null)
                          _InfoRow(
                            label: 'Sentadillas',
                            value: profile.squatsRange!,
                          ),
                        if (profile.dipsRange != null)
                          _InfoRow(label: 'Fondos', value: profile.dipsRange!),
                      ],
                    ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 32),
                  FilledButton.tonal(
                    onPressed: () async {
                      await ref.read(firebaseAuthProvider).signOut();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cerrar sesion'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const _StatusMessage(message: 'Cargando perfil...'),
      error: (_, __) =>
          const _StatusMessage(message: 'No pudimos cargar tu perfil.'),
    );
  }

  String _initialsFrom(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final first = parts.first;
      if (first.isEmpty) return '?';
      return first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.roleLabel,
  });

  final String initials;
  final String name;
  final String email;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.2),
            border: Border.all(color: colorScheme.primary, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                offset: Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Colors.black,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.primary),
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
          child: Text(
            roleLabel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.role, required this.active});

  final UserRole role;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = role == UserRole.colosoPrime
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.05);
    final borderColor = role == UserRole.colosoPrime
        ? colorScheme.primary
        : Colors.white24;
    final headline = role.label.toUpperCase();
    final subtitle = role == UserRole.coach
        ? 'Guia a la legion con sabiduria y ejemplo.'
        : role == UserRole.colosoPrime
        ? 'Acceso completo a planes, rituales y seguimiento del coach.'
        : 'Acceso esencial a planes base y comunidad.';
    final status = active ? 'ACTIVO' : 'SUSPENDIDO';
    final statusColor = active ? colorScheme.primary : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: background,
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                role == UserRole.coach
                    ? Icons.support_agent
                    : role == UserRole.colosoPrime
                    ? Icons.stars
                    : Icons.fitness_center,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: statusColor.withValues(alpha: 0.15),
            ),
            child: Text(
              "Estado: $status",
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isMono = false,
  });

  final String label;
  final String value;
  final bool isMono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 13,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 0.3,
              fontFamily: isMono ? 'RobotoMono' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF050505), Color(0xFF111111)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
