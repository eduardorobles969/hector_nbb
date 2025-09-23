import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      prompt: '¿Cómo quieres que te llame durante tus sesiones?',
      type: OnboardingInputType.freeText,
      hint: 'Escribe tu nombre o apodo favorito',
    ),
    OnboardingStep(
      id: 'fitnessLevel',
      prompt: 'Cuando entrenas hoy, ¿cómo describirías tu nivel?',
      type: OnboardingInputType.singleChoice,
      choices: ['novato', 'intermedio', 'avanzado'],
      choiceLabels: ['Novato', 'Intermedio', 'Avanzado'],
    ),
    OnboardingStep(
      id: 'goals',
      prompt: 'Marca tus objetivos principales para forjar tu plan.',
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
      prompt: 'Anota tu estatura para ajustar cargas y técnica.',
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
      prompt: '¿Cuál es tu peso actual? Me ayuda a balancear el plan.',
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
      prompt: '¿Cuántas dominadas logras sin pausa?',
      type: OnboardingInputType.singleChoice,
      choices: ['<10', '10-30', '30-50', '>50'],
    ),
    OnboardingStep(
      id: 'pushups',
      prompt: '¿Cuántas lagartijas seguidas te avientas?',
      type: OnboardingInputType.singleChoice,
      choices: ['<20', '20-40', '40-60', '>60'],
    ),
    OnboardingStep(
      id: 'squats',
      prompt: '¿Cuántas sentadillas continuas dominas?',
      type: OnboardingInputType.singleChoice,
      choices: ['<30', '30-60', '60-90', '>90'],
    ),
    OnboardingStep(
      id: 'dips',
      prompt: '¿Cuántos fondos en paralelas completas dominas?',
      type: OnboardingInputType.singleChoice,
      choices: ['<10', '10-30', '30-50', '>50'],
    ),
    OnboardingStep(
      id: 'email',
      prompt: '¿A qué correo te envío tus rutinas y acceso?',
      type: OnboardingInputType.freeText,
      hint: 'tu@correo.com',
    ),
    OnboardingStep(
      id: 'password',
      prompt: 'Último paso: crea una contraseña poderosa para tu cuenta.',
      type: OnboardingInputType.freeText,
      hint: 'Mínimo 6 caracteres',
    ),
  ];
});

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController(Ref ref)
      : _ref = ref,
        super(
          OnboardingState.initial(
            ref.read(onboardingStepsProvider),
          ),
        );

  final Ref _ref;

  static const _completionMessage =
      '¡Excelente! Dame un segundo para registrar todo y forjar tu plan personalizado.';

  List<OnboardingStep> get steps => _ref.read(onboardingStepsProvider);
  UserRepository get _repository => _ref.read(userRepositoryProvider);

  OnboardingStep get currentStep {
    final step = _currentStepOrNull;
    if (step == null) {
      throw StateError('No onboarding steps were configured.');
    }
    return step;
  }

  bool get _hasSteps => steps.isNotEmpty;

  int get _clampedStepIndex {
    if (!_hasSteps) {
      return 0;
    }
    return state.stepIndex.clamp(0, steps.length - 1).toInt();
  }

  OnboardingStep? get _currentStepOrNull {
    if (!_hasSteps) {
      return null;
    }
    final index = _clampedStepIndex;
    if (index < 0 || index >= steps.length) {
      return null;
    }
    return steps[index];
  }

  String? _bridgeForStep(OnboardingStep step, Map<String, dynamic> answers) {
    switch (step.id) {
      case 'fitnessLevel':
        final name = answers['displayName'];
        if (name is String && name.trim().isNotEmpty) {
          return 'Genial, $name. Cuéntame cómo te sientes con tu nivel actual.';
        }
        return 'Genial, cuéntame cómo te sientes con tu nivel actual.';
      case 'goals':
        return 'Perfecto. Ahora enfoquémonos en tus metas principales.';
      case 'gender':
        return 'Para personalizar mejor tu plan, dime con qué género te identificas.';
      case 'heightCm':
        return 'Tomemos tus medidas para ajustar las cargas. ¿Cuánto mides?';
      case 'weightKg':
        return 'Gracias. Ahora, ¿cuál es tu peso actual?';
      case 'pullups':
        return 'Hablemos de tu fuerza en barra.';
      case 'pushups':
        return 'Anotado. ¿Y cuántas lagartijas seguidas dominas?';
      case 'squats':
        return 'Excelente. Cuéntame de tus sentadillas continuas.';
      case 'dips':
        return 'Casi listo. ¿Cuántos fondos completos puedes hacer?';
      case 'email':
        return 'Ya casi terminamos. Necesito el correo donde te enviaré tus rutinas.';
      case 'password':
        return 'Último paso antes de pulir tu plan: crea una contraseña poderosa.';
      default:
        return null;
    }
  }

  /// Avanza al siguiente paso del onboarding.
  void _advance() {
    if (!_hasSteps) {
      if (!state.completed && mounted) {
        state = state.copyWith(
          completed: true,
          coachIsTyping: false,
        );
      }
      return;
    }

    final nextIndex = state.stepIndex + 1;
    if (nextIndex < steps.length) {
      final nextStep = steps[nextIndex];
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        stepIndex: nextIndex,
        coachIsTyping: true,
        multiSelection: const <String>{},
      );

      Future.delayed(const Duration(milliseconds: 520), () {
        if (!mounted) {
          return;
        }

        final current = state;
        if (current.stepIndex != nextIndex) {
          return;
        }

        final updatedEntries = [...current.entries];
        final bridge = _bridgeForStep(nextStep, current.answers);
        if (bridge != null && bridge.isNotEmpty) {
          updatedEntries
              .add(OnboardingChatEntry(text: bridge, fromCoach: true));
        }
        updatedEntries
            .add(OnboardingChatEntry(text: nextStep.prompt, fromCoach: true));
        if (!mounted) {
          return;
        }
        state = current.copyWith(
          entries: updatedEntries,
          coachIsTyping: false,
        );
      });
    } else {
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        completed: true,
        coachIsTyping: false,
        entries: [
          ...state.entries,
          const OnboardingChatEntry(
            text: OnboardingController._completionMessage,
            fromCoach: true,
          ),
        ],
      );
    }
  }

  /// Guarda una respuesta de texto y avanza.
  void submitText(String value) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final answers = {
      ...state.answers,
      step.id: trimmed,
    };
    final displayText = step.id == 'password' ? '••••••' : trimmed;
    if (!mounted) {
      return;
    }
    state = state.copyWith(
      answers: Map.unmodifiable(answers),
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: displayText, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Guarda una respuesta de opción única y avanza.
  void submitChoice(String choice) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {
      ...state.answers,
      step.id: choice,
    };

    // Mostrar el label amigable si existe.
    String label = choice;
    if (step.choiceLabels != null) {
      final idx = step.choices.indexOf(choice);
      if (idx >= 0 && idx < step.choiceLabels!.length) {
        label = step.choiceLabels![idx];
      }
    }

    if (!mounted) {
      return;
    }
    state = state.copyWith(
      answers: Map.unmodifiable(answers),
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: label, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Alterna una selección múltiple.
  void toggleMulti(String value) {
    final selection = {...state.multiSelection};
    if (selection.contains(value)) {
      selection.remove(value);
    } else {
      selection.add(value);
    }
    if (!mounted) {
      return;
    }
    state = state.copyWith(multiSelection: Set.unmodifiable(selection));
  }

  /// Confirma la selección múltiple actual.
  void confirmMulti() {
    if (state.multiSelection.isEmpty) return;
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {
      ...state.answers,
      step.id: state.multiSelection.toList(),
    };

    String labels = state.multiSelection.join(', ');
    if (step.choiceLabels != null) {
      labels = state.multiSelection
          .map((value) {
            final idx = step.choices.indexOf(value);
            if (idx >= 0 && idx < step.choiceLabels!.length) {
              return step.choiceLabels![idx];
            }
            return value;
          })
          .join(', ');
    }

    if (!mounted) {
      return;
    }
    state = state.copyWith(
      answers: Map.unmodifiable(answers),
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: labels, fromCoach: false),
      ],
      multiSelection: const <String>{},
    );
    _advance();
  }

  /// Confirma una opción numérica seleccionada.
  void submitNumeric(String value) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {
      ...state.answers,
      step.id: value,
    };
    final label = step.unit != null
        ? '$value ${step.unit}'
        : value;

    if (!mounted) {
      return;
    }
    state = state.copyWith(
      answers: Map.unmodifiable(answers),
      entries: [
        ...state.entries,
        OnboardingChatEntry(text: label, fromCoach: false),
      ],
    );
    _advance();
  }

  /// Guarda las respuestas en Firestore.
  Future<void> persist(User user) async {
    if (!mounted || state.isSaving || !state.completed) return;
    state = state.copyWith(isSaving: true);
    final rawAnswers = Map<String, dynamic>.from(state.answers);
    final email = (rawAnswers['email'] as String?)?.trim();
    final password = (rawAnswers['password'] as String?)?.trim();
    final displayName = (rawAnswers['displayName'] as String?)?.trim();
    final sanitizedAnswers = Map<String, dynamic>.from(rawAnswers)
      ..remove('password');
    if (email != null) {
      sanitizedAnswers['email'] = email;
    }
    try {
      User workingUser = FirebaseAuth.instance.currentUser ?? user;
      final previousEmail = workingUser.email;
      if (displayName != null && displayName.isNotEmpty) {
        await workingUser.updateDisplayName(displayName);
      }
      if (workingUser.isAnonymous) {
        if (email != null && password != null && email.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          final result = await workingUser.linkWithCredential(credential);
          workingUser = result.user ?? workingUser;
        } else {
          throw FirebaseAuthException(
            code: 'missing-email',
            message: 'Debes proporcionar un correo y una contraseña.',
          );
        }
      } else if (email != null && email.isNotEmpty && workingUser.email != email) {
        if (previousEmail == null ||
            previousEmail.isEmpty ||
            password == null ||
            password.isEmpty) {
          throw FirebaseAuthException(
            code: 'requires-recent-login',
            message: 'Debes iniciar sesión nuevamente para actualizar tu correo.',
          );
        }
        final credential = EmailAuthProvider.credential(
          email: previousEmail,
          password: password,
        );
        await workingUser.reauthenticateWithCredential(credential);
        await workingUser.updateEmail(email);
      }

      await _repository.ensureUserDocument(workingUser);
      await _repository.saveOnboardingIntake(
        workingUser.uid,
        answers: sanitizedAnswers,
      );
      if (!mounted) return;
      state = state.copyWith(answers: Map.unmodifiable(sanitizedAnswers));
    } finally {
      if (mounted) {
        state = state.copyWith(isSaving: false);
      }
    }
  }

  /// Permite reabrir un paso específico para que el atleta corrija su respuesta.
  void reopenStep(String stepId, {String? coachMessage}) {
    final targetIndex = steps.indexWhere((step) => step.id == stepId);
    if (targetIndex == -1) return;

    final prompt = steps[targetIndex].prompt;
    final updatedEntries = <OnboardingChatEntry>[];
    var promptFound = false;
    for (final entry in state.entries) {
      if (!promptFound && entry.fromCoach && entry.text == prompt) {
        promptFound = true;
        break;
      }
      updatedEntries.add(entry);
    }

    if (state.completed &&
        updatedEntries.isNotEmpty &&
        updatedEntries.last.fromCoach &&
        updatedEntries.last.text == _completionMessage) {
      updatedEntries.removeLast();
    }

    if (coachMessage != null && coachMessage.isNotEmpty) {
      updatedEntries
          .add(OnboardingChatEntry(text: coachMessage, fromCoach: true));
    }
    updatedEntries.add(OnboardingChatEntry(text: prompt, fromCoach: true));

    final updatedAnswers = Map<String, dynamic>.from(state.answers)
      ..removeWhere((key, _) {
        final idx = steps.indexWhere((step) => step.id == key);
        return idx != -1 && idx >= targetIndex;
      });

    if (!mounted) {
      return;
    }
    state = state.copyWith(
      entries: updatedEntries,
      answers: Map.unmodifiable(updatedAnswers),
      stepIndex: targetIndex,
      completed: false,
      coachIsTyping: false,
      multiSelection: const <String>{},
    );
  }
}
