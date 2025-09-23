import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrimeScreen extends StatelessWidget {
  const PrimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('PRIME Coloso')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'PRIME',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Únete a la familia PRIME',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accede a entrenamientos, seguimiento personalizado y la guía directa de nuestro equipo para alcanzar tus metas.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: const [
                    _PrimeBenefit(
                      title: 'Rutinas ilimitadas',
                      description:
                          'Desbloquea entrenamientos exclusivos y planificados para cada objetivo.',
                    ),
                    _PrimeBenefit(
                      title: 'Acompañamiento personal',
                      description:
                          'Conversa con tu coach para ajustar tu programa en tiempo real.',
                    ),
                    _PrimeBenefit(
                      title: 'Seguimiento avanzado',
                      description:
                          'Lleva el control detallado de tu progreso y métricas clave.',
                    ),
                    _PrimeBenefit(
                      title: 'Actualizaciones semanales',
                      description:
                          'Recibe nuevos retos y contenidos cada semana para mantener la motivación.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/coach'),
                  child: const Text('Hablar con un coach'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Un coach de Coloso te contactará para finalizar tu suscripción PRIME de forma personalizada.',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimeBenefit extends StatelessWidget {
  const _PrimeBenefit({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.flash_on, color: Colors.amber),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
