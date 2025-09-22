/// Types of input the onboarding flow supports.
enum OnboardingInputType { freeText, singleChoice, multiChoice, numericChoice }

/// Immutable definition of a single onboarding step.
class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.prompt,
    required this.type,
    this.choices = const [],
    this.allowMultiple = false, // Se usa solo si tu UI quiere leerlo.
    this.choiceLabels,
    this.unit,
    this.hint,
  });

  /// Unique identifier used as key in the persisted payload.
  final String id;

  /// Text shown to the user as question.
  final String prompt;

  /// How the step should gather the response.
  final OnboardingInputType type;

  /// Optional list of choices (used by choice/number steps).
  final List<String> choices;

  /// When true the step allows multi selection of [choices].
  final bool allowMultiple;

  /// Optional labels to show instead of raw [choices] values.
  final List<String>? choiceLabels;

  /// Optional unit suffix for numeric steps, e.g. "cm", "kg".
  final String? unit;

  /// Optional hint to show under the input.
  final String? hint;

  /// Returns the UI label for the value at [index].
  String labelAt(int index) {
    if (choiceLabels != null && choiceLabels!.length == choices.length) {
      return choiceLabels![index];
    }
    return choices[index];
  }
}

/// Simple chat entry model to paint bot/user bubbles.
class OnboardingChatEntry {
  const OnboardingChatEntry({required this.text, required this.fromCoach});

  /// Render text.
  final String text;

  /// True when bubble belongs to the coach/bot.
  final bool fromCoach;
}

/// Aggregate state the controller exposes to the UI.
class OnboardingState {
  const OnboardingState({
    required this.entries,
    required this.stepIndex,
    required this.answers,
    required this.multiSelection,
    required this.isSaving,
    required this.completed,
    this.coachIsTyping = false,
  });

  /// Messages already shown in the transcript.
  final List<OnboardingChatEntry> entries;

  /// Index of the current step in the flow.
  final int stepIndex;

  /// Map of answers collected so far.
  final Map<String, dynamic> answers;

  /// Temporal selection used by multi-choice steps.
  final Set<String> multiSelection;

  /// Flag used while persisting with Firestore.
  final bool isSaving;

  /// True while the coach bubble is pending.
  final bool coachIsTyping;

  /// True once the last step is answered.
  final bool completed;

  OnboardingState copyWith({
    List<OnboardingChatEntry>? entries,
    int? stepIndex,
    Map<String, dynamic>? answers,
    Set<String>? multiSelection,
    bool? isSaving,
    bool? completed,
    bool? coachIsTyping,
  }) {
    return OnboardingState(
      entries: entries ?? this.entries,
      stepIndex: stepIndex ?? this.stepIndex,
      answers: answers ?? this.answers,
      multiSelection: multiSelection ?? this.multiSelection,
      isSaving: isSaving ?? this.isSaving,
      completed: completed ?? this.completed,
      coachIsTyping: coachIsTyping ?? this.coachIsTyping,
    );
  }

  factory OnboardingState.initial(List<OnboardingStep> steps) {
    return OnboardingState(
      entries: [OnboardingChatEntry(text: steps.first.prompt, fromCoach: true)],
      stepIndex: 0,
      answers: <String, dynamic>{},
      multiSelection: <String>{},
      isSaving: false,
      completed: false,
      coachIsTyping: false,
    );
  }
}
