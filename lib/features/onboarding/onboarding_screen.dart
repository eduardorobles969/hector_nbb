import 'dart:math' as math;

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
  late final ScrollController _scrollController;
  ProviderSubscription<OnboardingState>? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _stateSubscription = ref.listen<OnboardingState>(
      onboardingControllerProvider,
      (previous, next) {
        final justCompleted =
            next.completed && !next.isSaving && previous?.completed != true;
        final shouldScroll =
            (previous?.entries.length ?? 0) != next.entries.length ||
                (previous?.coachIsTyping ?? false) != next.coachIsTyping;

        if (shouldScroll) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
        }

        if (justCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleCompletion();
          });
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _handleCompletion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = ref.read(onboardingControllerProvider.notifier);
    try {
      await controller.persist(user);
      if (!mounted) return;
      context.go('/profile');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use' ||
          e.code == 'invalid-email' ||
          e.code == 'missing-email' ||
          e.code == 'credential-already-in-use') {
        controller.reopenStep(
          'email',
          coachMessage:
              'Parece que ese correo ya está ocupado o no es válido. Compárteme uno nuevo.',
        );
      } else if (e.code == 'weak-password') {
        controller.reopenStep(
          'password',
          coachMessage:
              'Necesitamos una contraseña más fuerte. Escríbela de nuevo, por favor.',
        );
      }
      _showError(_messageForCode(e.code));
    } catch (_) {
      if (!mounted) return;
      controller.reopenStep(
        'email',
        coachMessage:
            'Vamos a intentarlo otra vez. Comparte tu correo y contraseña para registrarte.',
      );
      _showError('No pudimos guardar tu información. Intenta de nuevo.');
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese correo ya está vinculado a otra cuenta. Prueba con uno diferente.';
      case 'invalid-email':
        return 'El correo no es válido. Ajusta e inténtalo de nuevo.';
      case 'weak-password':
        return 'Tu contraseña debe tener al menos 6 caracteres.';
      case 'missing-email':
        return 'Necesitas compartir un correo y contraseña para crear tu cuenta.';
      case 'credential-already-in-use':
        return 'Las credenciales ya están en uso. ¿Ya tienes cuenta? Usa Iniciar sesión.';
      case 'network-request-failed':
        return 'Sin conexión. Verifica tu internet e inténtalo nuevamente.';
      case 'requires-recent-login':
        return 'Vuelve a iniciar sesión para completar este paso.';
      case 'operation-not-allowed':
        return 'La creación de cuentas está deshabilitada. Contacta al administrador.';
      default:
        return 'Algo no salió como esperábamos. Intenta de nuevo.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent.shade200,
        ),
      );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _stateSubscription?.close();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final steps = controller.steps;
    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              'Aún no hay pasos configurados para tu onboarding.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final step = controller.currentStep;
    final totalSteps = steps.length;

    int visibleStep;
    if (state.completed) {
      visibleStep = totalSteps;
    } else {
      visibleStep = state.stepIndex + 1;
      if (visibleStep > totalSteps) {
        visibleStep = totalSteps;
      }
      if (visibleStep < 0) {
        visibleStep = 0;
      }
    }
    final progress = totalSteps == 0 ? 0.0 : visibleStep / totalSteps;

    final messageCount = state.entries.length;
    final totalItems =
        messageCount + (state.coachIsTyping && !state.completed ? 1 : 0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0B0F), Color(0xFF070707)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _ChatHeader(
                progress: progress,
                step: visibleStep,
                totalSteps: totalSteps,
                isSaving: state.isSaving,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    const _ChatBackdrop(),
                    ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      itemCount: totalItems,
                      itemBuilder: (context, index) {
                        if (index >= messageCount) {
                          return const _TypingBubble();
                        }
                        final entry = state.entries[index];
                        return _ChatBubble(
                          key: ValueKey('${entry.fromCoach}-$index-${entry.text}'),
                          entry: entry,
                        );
                      },
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                child: state.completed
                    ? const SizedBox.shrink()
                    : _OnboardingInputArea(
                        key: ValueKey(step.id),
                        step: step,
                        state: state,
                        textController: _textController,
                      ),
              ),
              if (state.isSaving)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: _SavingBanner(),
                ),
            ],
          ),
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
    super.key,
  });

  final OnboardingStep step;
  final OnboardingState state;
  final TextEditingController textController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(onboardingControllerProvider.notifier);
    final theme = Theme.of(context);

    Widget card(Widget child) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.78),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    Widget buildChoicePill(
      String value, {
      bool selected = false,
      String? label,
      VoidCallback? onTap,
    }) {
      final display = label ?? value;
      return _ChoicePill(
        label: display,
        selected: selected,
        onTap: onTap,
      );
    }

    Widget buildFreeText() {
      final messenger = ScaffoldMessenger.of(context);
      final isEmailStep = step.id == 'email';
      final isPasswordStep = step.id == 'password';
      final isDisplayNameStep = step.id == 'displayName';

      void submit() {
        final text = textController.text.trim();
        if (text.isEmpty) return;
        if (isEmailStep && (!text.contains('@') || !text.contains('.'))) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Ingresa un correo válido para continuar.'),
              ),
            );
          return;
        }
        if (isPasswordStep && text.length < 6) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Tu contraseña debe tener al menos 6 caracteres.'),
              ),
            );
          return;
        }
        controller.submitText(text);
        textController.clear();
        FocusScope.of(context).unfocus();
      }

      String title;
      if (isEmailStep) {
        title = 'Escribe tu correo';
      } else if (isPasswordStep) {
        title = 'Define tu contraseña';
      } else if (isDisplayNameStep) {
        title = 'Comparte tu nombre';
      } else {
        title = 'Escribe tu respuesta';
      }

      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: step.hint ?? 'Comparte los detalles',
                        hintStyle:
                            const TextStyle(color: Colors.white54, fontSize: 14),
                        border: InputBorder.none,
                      ),
                      keyboardType:
                          isEmailStep ? TextInputType.emailAddress : TextInputType.text,
                      textCapitalization: isDisplayNameStep
                          ? TextCapitalization.words
                          : TextCapitalization.sentences,
                      autofillHints: isEmailStep
                          ? const [AutofillHints.email]
                          : isPasswordStep
                              ? const [AutofillHints.newPassword]
                              : null,
                      obscureText: isPasswordStep,
                      enableSuggestions: !isPasswordStep,
                      autocorrect: !isPasswordStep,
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: isPasswordStep || isEmailStep ? 1 : 4,
                      onSubmitted: (_) => submit(),
                    ),
                  ),
                  IconButton(
                    onPressed: submit,
                    splashRadius: 22,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSingleChoice() {
      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Elige una opción',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < step.choices.length; i++)
                  buildChoicePill(
                    step.choices[i],
                    label: step.labelAt(i),
                    onTap: () => controller.submitChoice(step.choices[i]),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildMultiChoice() {
      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Puedes elegir varias',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < step.choices.length; i++)
                  buildChoicePill(
                    step.choices[i],
                    label: step.labelAt(i),
                    selected: state.multiSelection.contains(step.choices[i]),
                    onTap: () => controller.toggleMulti(step.choices[i]),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: state.multiSelection.isEmpty
                  ? null
                  : () {
                      controller.confirmMulti();
                      FocusScope.of(context).unfocus();
                    },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Confirmar selección'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildNumericChoice() {
      final unit = step.unit;
      return card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona el valor',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final value in step.choices)
                  buildChoicePill(
                    value,
                    label: unit != null ? '$value $unit' : value,
                    onTap: () => controller.submitNumeric(value),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    switch (step.type) {
      case OnboardingInputType.freeText:
        return buildFreeText();
      case OnboardingInputType.singleChoice:
        return buildSingleChoice();
      case OnboardingInputType.multiChoice:
        return buildMultiChoice();
      case OnboardingInputType.numericChoice:
        return buildNumericChoice();
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry, super.key});

  final OnboardingChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final isCoach = entry.fromCoach;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isCoach ? Colors.white : Colors.black,
      height: 1.35,
    );

    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: isCoach
            ? null
            : const LinearGradient(
                colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
        color: isCoach ? const Color(0xFF15161B) : null,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: Radius.circular(isCoach ? 6 : 24),
          bottomRight: Radius.circular(isCoach ? 24 : 6),
        ),
        border: Border.all(
          color: isCoach ? Colors.white12 : Colors.transparent,
        ),
        boxShadow: [
          if (!isCoach)
            BoxShadow(
              color: const Color(0xFFFFB300).withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            )
          else
            const BoxShadow(
              color: Colors.black54,
              blurRadius: 18,
              offset: Offset(0, 14),
            ),
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      child: Text(entry.text, style: textStyle),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: isCoach ? 12 : 64,
        right: isCoach ? 64 : 12,
        top: 4,
        bottom: 18,
      ),
      child: Row(
        mainAxisAlignment:
            isCoach ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isCoach) ...[
            const _CoachAvatar(size: 40),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 320),
              tween: Tween<double>(begin: 0.8, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  alignment: Alignment.bottomRight,
                  child: child,
                );
              },
              child: bubble,
            ),
          ),
          if (!isCoach) ...[
            const SizedBox(width: 10),
            const _UserAvatar(),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 96, bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          _CoachAvatar(size: 36),
          SizedBox(width: 10),
          _TypingDots(),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: Image.asset(
          'assets/HectorNBB.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24),
        color: const Color(0xFF1C1C1C),
      ),
      child: const Icon(Icons.fitness_center_rounded, color: Colors.white70, size: 18),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = selected
        ? const LinearGradient(
            colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? const Color(0x1919191F) : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? const Color(0xFFFFB300) : Colors.white12,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFFB300).withOpacity(0.38),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final offset = (_controller.value + index * 0.2) % 1;
              final scale = 0.6 + (math.sin(offset * 2 * math.pi) + 1) * 0.2;
              return Padding(
                padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
                child: Transform.scale(
                  scale: scale,
                  child: const _Dot(),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.white70,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SavingBanner extends StatelessWidget {
  const _SavingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111115),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: const [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Guardando tu progreso...',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.progress,
    required this.step,
    required this.totalSteps,
    required this.isSaving,
  });

  final double progress;
  final int step;
  final int totalSteps;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _CoachAvatar(size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Héctor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isSaving
                                ? Colors.orangeAccent
                                : const Color(0xFF4CAF50),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSaving ? 'Afinando tu plan' : 'En línea',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '$step/$totalSteps',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
              backgroundColor: const Color(0x33121212),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBackdrop extends StatelessWidget {
  const _ChatBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0x44FFB300),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0x33FF8F00),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
