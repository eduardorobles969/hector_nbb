import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';
import '../../data/models/user_role.dart';
import '../profile/profile_providers.dart';

enum AuthScreenMode { signIn, signUp }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.initialMode = AuthScreenMode.signIn,
  });

  final AuthScreenMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLoading = false;
  late AuthScreenMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _isSignIn => _mode == AuthScreenMode.signIn;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final auth = ref.read(firebaseAuthProvider);
    try {
      UserCredential credential;
      if (_isSignIn) {
        credential = await auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        credential = await auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
      final user = credential.user;
      final userRepo = ref.read(userRepositoryProvider);
      if (user != null) {
        await userRepo.ensureUserDocument(user, defaultRole: UserRole.coloso);
        if (!_isSignIn && !user.emailVerified) {
          await user.sendEmailVerification();
        }
        final profile = await userRepo.fetchProfile(user.uid);
        final needsOnboarding = profile?.onboardingComplete != true;
        if (!mounted) return;
        if (!_isSignIn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enviamos un correo para verificar tu cuenta.'),
            ),
          );
        }
        context.go(needsOnboarding ? '/onboarding' : '/profile');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_messageForCode(e.code));
    } catch (_) {
      if (!mounted) return;
      _showError('Ocurrio un error inesperado. Intenta otra vez.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresa tu correo para recuperar la contrasena.');
      return;
    }
    try {
      await ref.read(firebaseAuthProvider).sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviamos instrucciones a $email')),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_messageForCode(e.code));
    } catch (_) {
      _showError('No pudimos enviar el correo. Intenta de nuevo.');
    }
  }

  void _switchMode(AuthScreenMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
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

  String _messageForCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Correo invalido.';
      case 'user-disabled':
        return 'Tu cuenta esta deshabilitada.';
      case 'user-not-found':
        return 'No encontramos ese correo.';
      case 'wrong-password':
        return 'Contrasena incorrecta.';
      case 'email-already-in-use':
        return 'Ese correo ya forja destino con nosotros.';
      case 'weak-password':
        return 'Necesitas al menos 6 caracteres en la contrasena.';
      default:
        return 'No pudimos completar la accion. Intenta de nuevo.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _ForgeBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _CrestHero(),
                      const SizedBox(height: 32),
                      _ModeSelector(mode: _mode, onChanged: _switchMode),
                      const SizedBox(height: 24),
                      _AuthCard(
                        formKey: _formKey,
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmController: _confirmController,
                        isSignIn: _isSignIn,
                        isLoading: _isLoading,
                        onSubmit: _submit,
                        onForgot: _sendReset,
                      ),
                      const SizedBox(height: 32),
                      const _CredoChips(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgeBackdrop extends StatelessWidget {
  const _ForgeBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF050505), Color(0xFF0F0F0F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Align(
          alignment: Alignment.topRight,
          child: Transform.translate(
            offset: const Offset(80, -60),
            child: Container(
              width: 280,
              height: 280,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x33FFD54F), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Transform.translate(
            offset: const Offset(-60, 90),
            child: Container(
              width: 260,
              height: 260,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0x3332CD32), Color(0x00000000)],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _CrestHero extends StatefulWidget {
  const _CrestHero();

  @override
  State<_CrestHero> createState() => _CrestHeroState();
}

class _CrestHeroState extends State<_CrestHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
        final sweep = (_controller.value * 360) * 3.14159 / 180;
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size.square(150),
                  painter: _TitleArcPainter(progress: sweep),
                ),
                ShaderMask(
                  shaderCallback: (rect) {
                    final offset = (_controller.value * 1.1) - 0.05;
                    return LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0),
                        Colors.white.withOpacity(0.86),
                        Colors.white.withOpacity(0),
                      ],
                      stops: [
                        (offset - 0.2).clamp(0.0, 1.0),
                        offset.clamp(0.0, 1.0),
                        (offset + 0.2).clamp(0.0, 1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 3,
                      ),
                      color: Colors.black,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          offset: Offset(0, 14),
                          blurRadius: 28,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Image.asset(
                      'assets/HectorNBB.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _HeroForgedTitle(),
            const SizedBox(height: 12),
            const Text(
              'Forja tu destino. Mantente indomable.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.mode, required this.onChanged});

  final AuthScreenMode mode;
  final ValueChanged<AuthScreenMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: AuthScreenMode.values.map((m) {
          final isActive = m == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? selectedColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  m == AuthScreenMode.signIn ? 'Ingresar' : 'Crear cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _AuthCard extends StatefulWidget {
  const _AuthCard({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmController,
    required this.isSignIn,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgot,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isSignIn;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgot;

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  bool _hidePass = true;
  bool _hideConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            offset: Offset(0, 16),
            blurRadius: 36,
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TextField(
              controller: widget.emailController,
              label: 'Correo electronico',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo.';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Correo invalido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _TextField(
              controller: widget.passwordController,
              label: 'Contrasena',
              obscureText: _hidePass,
              autofillHints: const [AutofillHints.password],
              suffix: IconButton(
                onPressed: () => setState(() => _hidePass = !_hidePass),
                icon: Icon(
                  _hidePass ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu contrasena.';
                }
                if (value.trim().length < 6) {
                  return 'Debe tener al menos 6 caracteres.';
                }
                return null;
              },
            ),
            if (!widget.isSignIn) ...[
              const SizedBox(height: 18),
              _TextField(
                controller: widget.confirmController,
                label: 'Confirma tu contrasena',
                obscureText: _hideConfirm,
                autofillHints: const [AutofillHints.password],
                suffix: IconButton(
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                  icon: Icon(
                    _hideConfirm ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Confirma tu contrasena.';
                  }
                  if (value.trim() != widget.passwordController.text.trim()) {
                    return 'Las contrasenas no coinciden.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 12),
            if (widget.isSignIn)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.isLoading ? null : widget.onForgot,
                  child: const Text(
                    'Recuperar contrasena',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.isLoading ? null : widget.onSubmit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.isSignIn ? 'Entrar al cuartel' : 'Forjar destino',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.amberAccent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.amberAccent),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        suffixIcon: suffix,
      ),
    );
  }
}

class _HeroForgedTitle extends StatelessWidget {
  const _HeroForgedTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'NEVER BE BROKEN',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2.4
                  ..color = Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              'NEVER BE BROKEN',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Color(0xFFF5D580),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 2,
          width: 140,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFB300), Color(0xFFFFE082)],
            ),
          ),
        ),
      ],
    );
  }
}

class _TitleArcPainter extends CustomPainter {
  const _TitleArcPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = const Color(0xFFFFD54F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(6), -0.8, progress, false, paint);
  }

  @override
  bool shouldRepaint(_TitleArcPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CredoChips extends StatelessWidget {
  const _CredoChips();

  static const items = [
    _CredoItem(label: 'Disciplina feroz', icon: Icons.flash_on),
    _CredoItem(label: 'Mentalidad inquebrantable', icon: Icons.shield_moon),
    _CredoItem(label: 'Voluntad de acero', icon: Icons.fitness_center),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CredoItem {
  const _CredoItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
