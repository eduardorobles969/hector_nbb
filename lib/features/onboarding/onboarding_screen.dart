import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_controller.dart';
import 'onboarding_models.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _textController = TextEditingController();
  late final ScrollController _scrollController;
  late final OnboardingController _controller;
  late OnboardingState _previousState;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _controller = OnboardingController();
    _previousState = _controller.state;
    _controller.addListener(_handleStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleStateChanged() {
    final previous = _previousState;
    final next = _controller.state;
    final steps = _controller.steps;

    final justCompleted =
        next.completed && !next.isSaving && previous.completed != true;
    final shouldScroll =
        previous.entries.length != next.entries.length ||
        previous.coachIsTyping != next.coachIsTyping;

    if (!next.completed && previous.stepIndex != next.stepIndex) {
      final nextIndex = next.stepIndex;
      if (nextIndex >= 0 && nextIndex < steps.length) {
        final nextStep = steps[nextIndex];
        if (nextStep.type != OnboardingInputType.freeText) {
          if (_textController.text.isNotEmpty) {
            _textController.clear();
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            FocusScope.of(context).unfocus();
          });
        }
      }
    }

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    if (justCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleCompletion();
      });
    }

    _previousState = next;
  }

  Future<void> _handleCompletion() async {
    final user = FirebaseAuth.instance.currentUser;

    try {
      final savedUser = await _controller.persist(user);
      if (savedUser != null) {
        await savedUser.reload();
      }
      final refreshed = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      if (refreshed != null &&
          !refreshed.isAnonymous &&
          refreshed.email != null &&
          !refreshed.emailVerified) {
        context.go('/verify-email');
      } else {
        context.go('/profile');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email-already-in-use' ||
          e.code == 'invalid-email' ||
          e.code == 'missing-email' ||
          e.code == 'credential-already-in-use') {
        _controller.reopenStep(
          'email',
          coachMessage:
              'Parece que ese correo ya está ocupado o no es válido. Compárteme uno nuevo.',
        );
      } else if (e.code == 'weak-password') {
        _controller.reopenStep(
          'password',
          coachMessage:
              'Necesitamos una contraseña más fuerte. Escríbela de nuevo, por favor.',
        );
      }
      _showError(_messageForCode(e.code));
    } catch (_) {
      if (!mounted) return;
      _controller.reopenStep(
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
      case 'user-not-found':
        return 'No pudimos crear tu cuenta. Intenta de nuevo.';
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
    _controller.removeListener(_handleStateChanged);
    _controller.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final steps = _controller.steps;
    if (steps.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Text(
              'Aún no hay pasos configurados para tu onboarding.',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final state = _controller.state;
        final controller = _controller;
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
                              key: ValueKey(
                                '${entry.fromCoach}-$index-${entry.text}',
                              ),
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
                            controller: controller,
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
      },
    );
  }
}

class _OnboardingInputArea extends StatelessWidget {
  const _OnboardingInputArea({
    required this.step,
    required this.state,
    required this.textController,
    required this.controller,
    super.key,
  });

  final OnboardingStep step;
  final OnboardingState state;
  final TextEditingController textController;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
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
      return _ChoicePill(label: display, selected: selected, onTap: onTap);
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
                content: Text(
                  'Tu contraseña debe tener al menos 6 caracteres.',
                ),
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
                        hintStyle: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                      keyboardType: isEmailStep
                          ? TextInputType.emailAddress
                          : TextInputType.text,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
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
                for (var i = 0; i < step.choices.length; i++)
                  buildChoicePill(
                    step.choices[i],
                    label: unit == null
                        ? step.choices[i]
                        : '${step.choices[i]} $unit',
                    onTap: () => controller.submitNumeric(step.choices[i]),
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

class _ChatBackdrop extends StatelessWidget {
  const _ChatBackdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              colors: [Colors.black87, Colors.transparent],
              stops: [0.0, 1.0],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(rect);
          },
          blendMode: BlendMode.dstOut,
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 1.4,
                center: Alignment.topCenter,
                colors: [Color(0xFF101015), Color(0xFF050507)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
        ),
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
    final percent = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _CoachAvatar(size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coach Héctor',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 16,
                          color: Color(0xFFFFB300),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tu plan está tomando forma',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    '$percent%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$step de $totalSteps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFB300)),
                  );
                },
              ),
            ),
          ),
          if (isSaving) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFFB300)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Guardando tu información...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.entry, super.key});

  final OnboardingChatEntry entry;

  @override
  Widget build(BuildContext context) {
    final alignment = entry.fromCoach
        ? Alignment.centerLeft
        : Alignment.centerRight;
    final colors = entry.fromCoach
        ? [const Color(0xFF1F1F1F), const Color(0xFF141414)]
        : [const Color(0xFFFFB300), const Color(0xFFFF8F00)];
    final textColor = entry.fromCoach ? Colors.white : Colors.black;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(
            entry.text,
            style: TextStyle(color: textColor, fontSize: 16, height: 1.32),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: _CoachTyping(),
      ),
    );
  }
}

class _CoachTyping extends StatelessWidget {
  const _CoachTyping();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1F1F1F),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _CoachAvatar(size: 36),
          SizedBox(width: 12),
          _TypingDots(),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({required this.size});

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
        child: Image.asset('assets/HectorNBB.png', fit: BoxFit.cover),
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
      child: const Icon(
        Icons.fitness_center_rounded,
        color: Colors.white70,
        size: 18,
      ),
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
      builder: (context, child) {
        return SizedBox(
          width: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(
                    0,
                    math.sin((_controller.value * 2 * math.pi) + (i * 0.6)) * 3,
                  ),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFB300),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SavingBanner extends StatelessWidget {
  const _SavingBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: const [
          _CoachAvatar(size: 42),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Guardando tu progreso. No cierres la app.',
              style: TextStyle(color: Colors.white70, height: 1.3),
            ),
          ),
          SizedBox(width: 16),
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Color(0xFFFFB300)),
            ),
          ),
        ],
      ),
    );
  }
}
