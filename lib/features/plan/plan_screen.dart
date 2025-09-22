import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plan_providers.dart';
import '../../data/models/adaptive_plan.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(planRepoProvider).ensurePlan());
  }

  Widget _actionTile(DailyAction action) {
    Color tone(BuildContext context) {
      final cs = Theme.of(context).colorScheme;
      switch (action.status) {
        case 'done':
          return cs.primaryContainer;
        case 'skipped':
          return cs.errorContainer;
        case 'snoozed':
          return cs.tertiaryContainer;
        default:
          return cs.surfaceContainerHighest;
      }
    }

    final surface = tone(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [surface, surface.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.25),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.flash_on, color: Colors.amberAccent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        fontSize: 14,
                      ),
                    ),
                    if (action.note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          action.note,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              _StatusChip(status: action.status),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    ref.read(planRepoProvider).completeAction(action.id),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Lo hice'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(planRepoProvider).skipAction(action.id),
                icon: const Icon(Icons.close),
                label: const Text('No pude'),
              ),
              TextButton.icon(
                onPressed: () =>
                    ref.read(planRepoProvider).snoozeAction(action.id),
                icon: const Icon(Icons.snooze),
                label: const Text('Posponer'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Plan adaptativo')),
      body: planAsync.when(
        data: (plan) {
          if (plan == null) {
            return const Center(child: Text('Cargando tu plan...'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Tus metas',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              for (final goal in plan.goals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(goal)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Acciones de hoy (max 3)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (plan.today.isEmpty)
                const Text('Tu coach definira tus proximas acciones.'),
              for (final action in plan.today) _actionTile(action),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    late final Color tone;
    late final String label;
    late final IconData icon;
    switch (status) {
      case 'done':
        tone = const Color(0xFF64FFDA);
        label = 'Completado';
        icon = Icons.check_circle;
        break;
      case 'skipped':
        tone = Colors.redAccent;
        label = 'Omitido';
        icon = Icons.close_rounded;
        break;
      case 'snoozed':
        tone = colorScheme.tertiary;
        label = 'Pospuesto';
        icon = Icons.snooze;
        break;
      default:
        tone = Colors.white38;
        label = 'Pendiente';
        icon = Icons.hourglass_bottom;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: tone.withValues(alpha: 0.18),
        border: Border.all(color: tone.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
