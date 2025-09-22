import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isStarting = false;

  void _openAuth() {
    context.go('/auth');
  }

  Future<void> _startOnboarding() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);
    final auth = ref.read(firebaseAuthProvider);

    try {
      final current = auth.currentUser;
      if (current == null) {
        await auth.signInAnonymously();
      }
      if (!mounted) return;
      context.go('/onboarding');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(_messageForCode(e.code));
    } catch (_) {
      if (!mounted) return;
      _showError('No pudimos iniciar el cuestionario. Intenta de nuevo.');
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Sin conexión. Verifica tu internet e intenta otra vez.';
      case 'operation-not-allowed':
        return 'La autenticación anónima no está disponible. Contacta al admin.';
      default:
        return 'Ocurrió un error al iniciar. Intenta de nuevo.';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(child: _WelcomeHero()),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Bienvenido a ',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Never Be Broken',
                          style: TextStyle(
                            color: Color(0xFFFF1744),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Forja tu cuenta, responde el cuestionario inicial y te guiaremos paso a paso.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _PageDot(active: true),
                      SizedBox(width: 8),
                      _PageDot(active: false),
                      SizedBox(width: 8),
                      _PageDot(active: false),
                    ],
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _openAuth,
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('INICIAR SESIÓN'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.7)),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _startOnboarding,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isStarting
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.bolt_rounded, key: ValueKey('bolt')),
                    ),
                    label: Text(_isStarting ? 'CREANDO TU ESPACIO...' : 'EMPEZAR AHORA'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1C1C), Color(0xFF090909)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/HectorNBB.png',
              fit: BoxFit.contain,
              color: Colors.white.withOpacity(0.12),
              colorBlendMode: BlendMode.srcATop,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/HectorNBB.png',
                          fit: BoxFit.cover,
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.6),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Forge Mode',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Rutinas de elite, resultados reales.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _PageDot extends StatelessWidget {
  const _PageDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 12 : 8,
      height: active ? 12 : 8,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
