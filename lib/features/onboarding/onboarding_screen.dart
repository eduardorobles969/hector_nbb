import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_controller.dart';
import 'onboarding_models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final step = controller.currentStep;

    Future<void> finishIfNeeded() async {
      if (!state.completed || state.isSaving) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await controller.persist(user);
      if (!mounted) return;
      context.go('/profile');
    }

    // Ejecuta la verificación al construir.
    finishIfNeeded();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Forja tu destino'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  final alignment = entry.fromCoach
                      ? Alignment.centerLeft
                      : Alignment.centerRight;
                  final bubbleColor = entry.fromCoach
                      ? const Color(0xFF101010)
                      : const Color(0xFFFFB300);
                  final textColor = entry.fromCoach
                      ? Colors.white
                      : Colors.black;
                  return Align(
                    alignment: alignment,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: BorderRadius.circular(20),
                        border: entry.fromCoach
                            ? Border.all(color: Colors.white12)
                            : null,
                      ),
                      child: Text(
                        entry.text,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!state.completed)
              _OnboardingInputArea(
                step: step,
                state: state,
                textController: _textController,
              ),
            if (state.isSaving)
              const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingInputArea extends ConsumerWidget {
  const _OnboardingInputArea({
    required this.step,
    required this.state,
    required this.textController,
  });

  final OnboardingStep step;
  final OnboardingState state;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final spacing = const SizedBox(height: 12);

    Widget buildChoices({required bool allowMulti}) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (var i = 0; i < step.choices.length; i++)
            ChoiceChip(
              label: Text(step.labelAt(i)),
              selected: allowMulti
                  ? state.multiSelection.contains(step.choices[i])
                  : false,
              onSelected: (selected) {
                if (allowMulti) {
                  controller.toggleMulti(step.choices[i]);
                } else {
                  controller.submitChoice(step.choices[i]);
                }
              },
            ),
        ],
      );
    }

    switch (step.type) {
      case OnboardingInputType.freeText:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: step.hint ?? 'Escribe tu respuesta',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF101010),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onSubmitted: (value) {
                  controller.submitText(value);
                  textController.clear();
                },
              ),
              spacing,
              ElevatedButton(
                onPressed: () {
                  controller.submitText(textController.text);
                  textController.clear();
                },
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

      case OnboardingInputType.singleChoice:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [buildChoices(allowMulti: false)],
          ),
        );

      case OnboardingInputType.multiChoice:
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildChoices(allowMulti: true),
              spacing,
              ElevatedButton(
                onPressed: state.multiSelection.isEmpty
                    ? null
                    : controller.confirmMulti,
                child: const Text('Confirmar selección'),
              ),
            ],
          ),
        );

      case OnboardingInputType.numericChoice:
        // Asegúrate de que la lista de choices no venga vacía.
        final initial = (step.choices.isNotEmpty) ? step.choices.first : null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: Colors.black,
                value: initial,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF101010),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: step.choices
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        // Muestra "170 cm" o "80 kg" cuando aplica.
                        child: Text(
                          step.unit != null ? '$value ${step.unit}' : value,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.submitNumeric(value);
                  }
                },
              ),
            ],
          ),
        );
    }
  }
}
