import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_providers.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  bool _isSending = false;
  bool _isChecking = false;

  Future<void> _resend() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No encontramos tu sesi\u00f3n activa.')),
      );
      context.go('/auth');
      return;
    }
    setState(() => _isSending = true);
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enviamos el correo a ${user.email}.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'too-many-requests'
          ? 'Demasiados intentos. Espera unos minutos.'
          : 'No pudimos reenviar el correo. Intenta de nuevo.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _check() async {
    final auth = ref.read(firebaseAuthProvider);
    final user = auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/auth');
      return;
    }
    setState(() => _isChecking = true);
    try {
      await user.reload();
      final refreshed = auth.currentUser;
      if (refreshed != null) {
        await refreshed.getIdToken(true);
      }
      if (refreshed != null &&
          refreshed.email != null &&
          refreshed.emailVerified) {
        if (!mounted) return;
        context.go('/profile');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A\u00fan no se confirma el correo. Revisa tu inbox.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    final user = authState.asData?.value;
    final email = user?.email ?? 'tu correo';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mark_email_read_rounded,
                    size: 84,
                    color: Colors.amberAccent.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Confirma tu correo',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enviamos un enlace a $email. Abre el correo y confirma tu cuenta para continuar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isChecking ? null : _check,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ya verifiqu\u00e9 mi correo'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isSending ? null : _resend,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reenviar correo'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _signOut,
                    child: const Text(
                      'Cambiar correo',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
