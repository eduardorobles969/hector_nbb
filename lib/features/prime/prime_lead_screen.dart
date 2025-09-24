import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrimeLeadScreen extends StatefulWidget {
  const PrimeLeadScreen({super.key});

  @override
  State<PrimeLeadScreen> createState() => _PrimeLeadScreenState();
}

class _PrimeLeadScreenState extends State<PrimeLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(
    text: 'Quiero activar PRIME COLOSO lo antes posible.',
  );

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      final name = user.displayName;
      if (name != null && name.isNotEmpty) {
        _nameCtrl.text = name;
      }
      final phone = user.phoneNumber;
      if (phone != null && phone.isNotEmpty) {
        _phoneCtrl.text = phone;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _goalCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitas iniciar sesión para solicitar tu acceso PRIME.'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    try {
      final leadRef = _db.collection('prime_leads').doc(user.uid);
      final leadSnap = await leadRef.get();
      final isNewLead = leadSnap.exists != true;

      final basePayload = {
        'uid': user.uid,
        'email': user.email ?? '',
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'goal': _goalCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'status': 'pending_coach_assignment',
        'source': 'app',
        'submittedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isNewLead) {
        await leadRef.set({
          ...basePayload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await leadRef.update(basePayload);
      }

      await _db.collection('users').doc(user.uid).set({
        'role': 'coloso_prime',
        'roles': FieldValue.arrayUnion(['coloso_prime']),
        'primeStatus': 'pending_coach_assignment',
        'primeActivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      final goToCoach = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const _PrimeLeadSuccessDialog(),
      );

      if (!mounted) return;
      if (goToCoach == true) {
        context.go('/coach');
      } else {
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      if (e.code == 'permission-denied') {
        _showError(
          'Tu sesión no tiene permisos para enviar la solicitud. Cierra y vuelve a iniciar sesión para intentarlo de nuevo.',
        );
      } else {
        _showError(e.message);
      }
    } catch (_) {
      if (!mounted) return;
      _showError(null);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showError(String? details) {
    final message = details == null || details.isEmpty
        ? 'No pudimos enviar tu solicitud. Intenta nuevamente en unos minutos.'
        : 'No pudimos enviar tu solicitud: $details';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: const Color(0xFF1B1B1B),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF2C2C2C)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD0202A), width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Activa PRIME COLOSO',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comparte tus datos y un coach iniciará el cierre de tu membresía PRIME COLOSO.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Nombre completo'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _phoneCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('WhatsApp o teléfono de contacto'),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Necesitamos un contacto' : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _goalCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('¿Cuál es tu objetivo Coloso?'),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _messageCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration('Mensaje para tu coach'),
                  maxLines: 5,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _sending ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD0202A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Enviar solicitud',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Después de validar tu pago manualmente activaremos tu cuenta como PRIME COLOSO para que desbloquees todos los accesos.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimeLeadSuccessDialog extends StatelessWidget {
  const _PrimeLeadSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: const Text(
        'Solicitud enviada',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'Activamos tu acceso PRIME y nuestro equipo asignará a tu coach. Ya puedes abrir la pestaña "Coach" para conversar en'
        ' cuanto se vincule y revisar tus planes personalizados.',
        style: TextStyle(color: Colors.white70, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: Colors.white70),
          child: const Text('Seguir explorando'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Ir con mi coach'),
        ),
      ],
    );
  }
}
