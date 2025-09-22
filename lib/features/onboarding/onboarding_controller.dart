import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/user_repository.dart';
import '../profile/profile_providers.dart';
import 'onboarding_models.dart';

/// Provee la lista de pasos del onboarding.
/// NOTA: no usamos `const` en la lista para evitar conflictos si tu constructor
/// no es const. (Puedes volverlo más adelante si quieres).
final onboardingStepsProvider = Provider<List<OnboardingStep>>((ref) {
  return [
    OnboardingStep(
      id: 'displayName',
      prompt: '¿Cómo te llamas?',
      type: OnboardingInputType.freeText,
      hint: 'Escribe tu nombre como deseas que el coach te llame',
    ),
    OnboardingStep(
      id: 'fitnessLevel',
      prompt: '¿Qué nivel de condición tienes actualmente?',
      type: OnboardingInputType.singleChoice,
      choices: ['novato', 'intermedio', 'avanzado'],
      choiceLabels: ['Novato', 'Intermedio', 'Avanzado'],
    ),
    OnboardingStep(
      id: 'goals',
      prompt: '¿Cuáles son tus objetivos principales?',
      type: OnboardingInputType.multiChoice,
      choices: ['fuerza', 'musculo', 'bajar_grasa', 'resistir', 'tecnica'],
      choiceLabels: [
        'Forjar fuerza',
        'Ganar músculo',
        'Reducir grasa',
        'Mejorar resistencia',
        'Pulir técnica',
      ],
    ),
    OnboardingStep(
      id: 'gender',
      prompt: '¿Con qué género te identificas?',
      type: OnboardingInputType.singleChoice,
      choices: ['masculino', 'femenino', 'otro'],
      choiceLabels: ['Masculino', 'Femenino', 'Prefiero no decir'],
    ),
    OnboardingStep(
      id: 'heightCm',
      prompt: '¿Cuánto mides?',
      type: OnboardingInputType.numericChoice,
      choices: [
        '150',
        '155',
        '160',
        '165',
        '170',
        '175',
        '180',
        '185',
        '190',
        '195',
        '200',
        '205',
      ],
      unit: 'cm',
    ),
    OnboardingStep(
      id: 'weightKg',
      prompt: '¿Cuál es tu peso actual?',
      type: OnboardingInputType.numericChoice,
      choices: [
        '55',
        '60',
        '65',
        '70',
        '75',
        '80',
        '85',
        '90',
        '95',
        '100',
        '105',
        '110',
      ],
      unit: 'kg',
    ),
    OnboardingStep(
      id: 'pullups',
      prompt: '¿Cuántas dominadas puedes hacer sin pausa?',
      type: OnboardingInputType.singleChoice,
      choices: ['<10', '10-30', '30-50', '>50'],
    ),
    OnboardingStep(
      id: 'pushups',
      prompt: '¿Cuántas lagartijas puedes hacer sin pausa?',
      type: OnboardingInputType.singleChoice,
      choices: ['<20', '20-40', '40-60', '>60'],
    ),
    OnboardingStep(
      id: 'squats',
      prompt: '¿Cuántas sentadillas continuas logras?',
      type: OnboardingInputType.singleChoice,
      choices: ['<30', '30-60', '60-90', '>90'],
    ),
    OnboardingStep(
      id: 'dips',
      prompt: '¿Cuántos fondos en paralelas completas tienes?',
      type: OnboardingInputType.singleChoice,
      choices: ['<10', '10-30', '30-50', '>50'],
    ),
  ];
});

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  List<OnboardingStep> get steps => ref.read(onboardingStepsProvider);
  UserRepository get _repository => ref.read(userRepositoryProvider);

  @override
  OnboardingState build() {
    final initialSteps = ref.watch(onboardingStepsProvider);
    return OnboardingState.initial(initialSteps);
  }

  OnboardingStep get currentStep => steps[state.stepIndex];

  /// Avanza al siguiente paso del onboarding.
  void _advance() {
    final nextIndex = state.stepIndex + 1;
    if (nextIndex < steps.length) {
      final prompt = steps[nextIndex].prompt;
      state = state.copyWith(
        stepIndex: nextIndex,
        coachIsTyping: true,
        multiSelection: <String>{},
      );

      Future.delayed(const Duration(milliseconds: 520), () {
        final current = state;
        if (current.stepIndex != nextIndex) {
          return;
        }

        final updatedEntries = [
          ...current.entries,
          OnboardingChatEntry(text: prompt, fromCoach: true),
        ];
        state = current.copyWith(
          entries: updatedEntries,
          coachIsTyping: false,
        );
      });
    } else {
      state = state.copyWith(
        completed: true,
        coachIsTyping: false,
        entries: [
          ...state.entries,
          const OnboardingChatEntry(
            text:
                'Increíble, dame un segundo para registrar todo y pulir tu plan.',
            fromCoach: true,
          ),
        ],
      );
    }
  }

  /// Guarda una respuesta de texto y avanza.
  void submitText(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final answers = Map<String, dynamic>.from(state.answers);
    answers[currentStep.id] = trimmed;
    state = state.copyWith(
      answers: answers,
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: trimmed, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Guarda una respuesta de opción única y avanza.
  void submitChoice(String choice) {
    final answers = Map<String, dynamic>.from(state.answers);
    answers[currentStep.id] = choice;

    // Mostrar el label amigable si existe.
    String label = choice;
    if (currentStep.choiceLabels != null) {
      final idx = currentStep.choices.indexOf(choice);
      if (idx >= 0 && idx < currentStep.choiceLabels!.length) {
        label = currentStep.choiceLabels![idx];
      }
    }

    state = state.copyWith(
      answers: answers,
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: label, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Alterna una selección múltiple.
  void toggleMulti(String value) {
    final selection = Set<String>.from(state.multiSelection);
    if (selection.contains(value)) {
      selection.remove(value);
    } else {
      selection.add(value);
    }
    state = state.copyWith(multiSelection: selection);
  }

  /// Confirma la selección múltiple actual.
  void confirmMulti() {
    if (state.multiSelection.isEmpty) return;

    final answers = Map<String, dynamic>.from(state.answers);
    answers[currentStep.id] = state.multiSelection.toList();

    String labels = state.multiSelection.join(', ');
    if (currentStep.choiceLabels != null) {
      labels = state.multiSelection
          .map((value) {
            final idx = currentStep.choices.indexOf(value);
            if (idx >= 0 && idx < currentStep.choiceLabels!.length) {
              return currentStep.choiceLabels![idx];
            }
            return value;
          })
          .join(', ');
    }

    state = state.copyWith(
      answers: answers,
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: labels, fromCoach: false),
      ],
      multiSelection: <String>{},
    );
    _advance();
  }

  /// Confirma una opción numérica seleccionada.
  void submitNumeric(String value) {
    final answers = Map<String, dynamic>.from(state.answers);
    final label = currentStep.unit != null
        ? '$value ${currentStep.unit}'
        : value;
    answers[currentStep.id] = value;

    state = state.copyWith(
      answers: answers,
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: label, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Guarda las respuestas en Firestore.
  Future<void> persist(User user) async {
    if (state.isSaving || !state.completed) return;
    state = state.copyWith(isSaving: true);
    try {
      await _repository.saveOnboardingIntake(user.uid, answers: state.answers);
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}
