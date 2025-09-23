import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/user_repository.dart';
import 'onboarding_models.dart';

/// Mensaje final que muestra el coach al terminar el onboarding.
const _completionMessage =
    '¡Excelente! Dame un segundo para registrar todo y forjar tu plan personalizado.';

/// Genera la lista base de pasos que conforman el onboarding.
List<OnboardingStep> buildDefaultOnboardingSteps() {
  return const [
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
}

/// Controlador del flujo de onboarding sin dependencias de Riverpod.
class OnboardingController extends ChangeNotifier {
  OnboardingController({
    List<OnboardingStep>? steps,
    UserRepository? repository,
  }) : _steps = List.unmodifiable(steps ?? buildDefaultOnboardingSteps()),
       _repository = repository ?? UserRepository(),
       _state = OnboardingState.initial(steps ?? buildDefaultOnboardingSteps());

  final List<OnboardingStep> _steps;
  final UserRepository _repository;

  OnboardingState _state;
  bool _disposed = false;

  OnboardingState get state => _state;
  List<OnboardingStep> get steps => _steps;

  OnboardingStep get currentStep {
    final step = _currentStepOrNull;
    if (step == null) {
      throw StateError('No onboarding steps were configured.');
    }
    return step;
  }

  bool get _hasSteps => _steps.isNotEmpty;

  int get _clampedStepIndex {
    if (!_hasSteps) {
      return 0;
    }
    return _state.stepIndex.clamp(0, _steps.length - 1).toInt();
  }

  OnboardingStep? get _currentStepOrNull {
    if (!_hasSteps) {
      return null;
    }
    final index = _clampedStepIndex;
    if (index < 0 || index >= _steps.length) {
      return null;
    }
    return _steps[index];
  }

  void _updateState(OnboardingState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
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

  void _advance() {
    if (!_hasSteps) {
      if (!_state.completed) {
        _updateState(_state.copyWith(completed: true, coachIsTyping: false));
      }
      return;
    }

    final nextIndex = _state.stepIndex + 1;
    if (nextIndex < _steps.length) {
      final nextStep = _steps[nextIndex];
      _updateState(
        _state.copyWith(
          stepIndex: nextIndex,
          coachIsTyping: true,
          multiSelection: const <String>{},
        ),
      );

      Future.delayed(const Duration(milliseconds: 520), () {
        if (_disposed) {
          return;
        }

        final current = _state;
        if (current.stepIndex != nextIndex) {
          return;
        }

        final updatedEntries = [...current.entries];
        final bridge = _bridgeForStep(nextStep, current.answers);
        if (bridge != null && bridge.isNotEmpty) {
          updatedEntries.add(
            OnboardingChatEntry(text: bridge, fromCoach: true),
          );
        }
        updatedEntries.add(
          OnboardingChatEntry(text: nextStep.prompt, fromCoach: true),
        );

        _updateState(
          current.copyWith(entries: updatedEntries, coachIsTyping: false),
        );
      });
    } else {
      _updateState(
        _state.copyWith(
          completed: true,
          coachIsTyping: false,
          entries: [
            ..._state.entries,
            const OnboardingChatEntry(
              text: _completionMessage,
              fromCoach: true,
            ),
          ],
        ),
      );
    }
  }

  void submitText(String value) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final answers = {..._state.answers, step.id: trimmed};
    final displayText = step.id == 'password' ? '••••••' : trimmed;

    _updateState(
      _state.copyWith(
        answers: Map.unmodifiable(answers),
        entries: [
          ..._state.entries,
          OnboardingChatEntry(text: displayText, fromCoach: false),
        ],
      ),
    );
    _advance();
  }

  void submitChoice(String choice) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {..._state.answers, step.id: choice};

    String label = choice;
    if (step.choiceLabels != null) {
      final idx = step.choices.indexOf(choice);
      if (idx >= 0 && idx < step.choiceLabels!.length) {
        label = step.choiceLabels![idx];
      }
    }

    _updateState(
      _state.copyWith(
        answers: Map.unmodifiable(answers),
        entries: [
          ..._state.entries,
          OnboardingChatEntry(text: label, fromCoach: false),
        ],
      ),
    );
    _advance();
  }

  void toggleMulti(String value) {
    final selection = {..._state.multiSelection};
    if (selection.contains(value)) {
      selection.remove(value);
    } else {
      selection.add(value);
    }

    _updateState(_state.copyWith(multiSelection: Set.unmodifiable(selection)));
  }

  void confirmMulti() {
    if (_state.multiSelection.isEmpty) return;
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {
      ..._state.answers,
      step.id: _state.multiSelection.toList(),
    };

    String labels = _state.multiSelection.join(', ');
    if (step.choiceLabels != null) {
      labels = _state.multiSelection
          .map((value) {
            final idx = step.choices.indexOf(value);
            if (idx >= 0 && idx < step.choiceLabels!.length) {
              return step.choiceLabels![idx];
            }
            return value;
          })
          .join(', ');
    }

    _updateState(
      _state.copyWith(
        answers: Map.unmodifiable(answers),
        entries: [
          ..._state.entries,
          OnboardingChatEntry(text: labels, fromCoach: false),
        ],
        multiSelection: const <String>{},
      ),
    );
    _advance();
  }

  void submitNumeric(String value) {
    final step = _currentStepOrNull;
    if (step == null) return;

    final answers = {..._state.answers, step.id: value};
    final label = step.unit != null ? '$value ${step.unit}' : value;

    _updateState(
      _state.copyWith(
        answers: Map.unmodifiable(answers),
        entries: [
          ..._state.entries,
          OnboardingChatEntry(text: label, fromCoach: false),
        ],
      ),
    );
    _advance();
  }

  Future<void> persist(User user) async {
    if (_disposed || _state.isSaving || !_state.completed) return;
    _updateState(_state.copyWith(isSaving: true));

    final rawAnswers = Map<String, dynamic>.from(_state.answers);
    final email = (rawAnswers['email'] as String?)?.trim();
    final password = (rawAnswers['password'] as String?)?.trim();
    final displayName = (rawAnswers['displayName'] as String?)?.trim();

    // Lo que guardaremos en Firestore (sin password)
    final sanitizedAnswers = Map<String, dynamic>.from(rawAnswers)
      ..remove('password');
    if (email != null) {
      sanitizedAnswers['email'] = email;
    }

    try {
      var workingUser = FirebaseAuth.instance.currentUser ?? user;

      // 1) Actualiza displayName si viene
      if (displayName != null && displayName.isNotEmpty) {
        await workingUser.updateDisplayName(displayName);
      }

      // 2) Si el usuario es anónimo, hacemos "upgrade" linkeando email/password
      if (workingUser.isAnonymous) {
        if (email != null && password != null && email.isNotEmpty) {
          final credential = EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          final result = await workingUser.linkWithCredential(credential);
          workingUser = result.user ?? workingUser; // ya no es anónimo
        } else {
          throw FirebaseAuthException(
            code: 'missing-email',
            message: 'Debes proporcionar un correo y una contraseña.',
          );
        }
      } else {
        // 3) Si NO es anónimo y el email cambió, usar verifyBeforeUpdateEmail (firebase_auth v6)
        if (email != null && email.isNotEmpty && workingUser.email != email) {
          try {
            await workingUser.verifyBeforeUpdateEmail(email);
            // Marcamos que el cambio está pendiente hasta que el usuario confirme el email
            sanitizedAnswers['pendingEmail'] = email;

            // Mensaje en el chat para avisar la verificación
            final updatedEntries = [
              ..._state.entries,
              const OnboardingChatEntry(
                text:
                    'Te envié un correo para confirmar tu nuevo email. Abre el enlace para completar el cambio.',
                fromCoach: true,
              ),
            ];
            _updateState(_state.copyWith(entries: updatedEntries));
          } on FirebaseAuthException catch (e) {
            if (e.code == 'requires-recent-login') {
              // Reautenticación requerida para cambiar el correo (operación sensible)
              throw FirebaseAuthException(
                code: e.code,
                message:
                    'Por seguridad, vuelve a iniciar sesión para cambiar tu correo y vuelve a intentarlo.',
              );
            } else {
              rethrow;
            }
          }
        }
      }

      // 4) Asegura el documento del usuario y guarda el intake del onboarding
      await _repository.ensureUserDocument(workingUser);
      await _repository.saveOnboardingIntake(
        workingUser.uid,
        answers: sanitizedAnswers,
      );

      if (_disposed) return;
      _updateState(
        _state.copyWith(answers: Map.unmodifiable(sanitizedAnswers)),
      );
    } finally {
      if (!_disposed) {
        _updateState(_state.copyWith(isSaving: false));
      }
    }
  }

  void reopenStep(String stepId, {String? coachMessage}) {
    final targetIndex = _steps.indexWhere((step) => step.id == stepId);
    if (targetIndex == -1) return;

    final prompt = _steps[targetIndex].prompt;
    final updatedEntries = <OnboardingChatEntry>[];
    var promptFound = false;
    for (final entry in _state.entries) {
      if (!promptFound && entry.fromCoach && entry.text == prompt) {
        promptFound = true;
        break;
      }
      updatedEntries.add(entry);
    }

    if (_state.completed &&
        updatedEntries.isNotEmpty &&
        updatedEntries.last.fromCoach &&
        updatedEntries.last.text == _completionMessage) {
      updatedEntries.removeLast();
    }

    if (coachMessage != null && coachMessage.isNotEmpty) {
      updatedEntries.add(
        OnboardingChatEntry(text: coachMessage, fromCoach: true),
      );
    }
    updatedEntries.add(OnboardingChatEntry(text: prompt, fromCoach: true));

    final updatedAnswers = Map<String, dynamic>.from(_state.answers)
      ..removeWhere((key, _) {
        final idx = _steps.indexWhere((step) => step.id == key);
        return idx != -1 && idx >= targetIndex;
      });

    _updateState(
      _state.copyWith(
        entries: updatedEntries,
        answers: Map.unmodifiable(updatedAnswers),
        stepIndex: targetIndex,
        completed: false,
        coachIsTyping: false,
        multiSelection: const <String>{},
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
