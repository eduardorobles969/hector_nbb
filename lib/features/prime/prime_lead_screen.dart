import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/models/prime_lead.dart';
import 'prime_lead_providers.dart';
import 'prime_lead_copy.dart';

class PrimeLeadScreen extends ConsumerStatefulWidget {
  const PrimeLeadScreen({super.key});

  @override
  ConsumerState<PrimeLeadScreen> createState() => _PrimeLeadScreenState();
}

class _PrimeLeadScreenState extends ConsumerState<PrimeLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _messageCtrl = TextEditingController(
    text: 'Quiero activar PRIME COLOSO lo antes posible.',
  );

  final _auth = FirebaseAuth.instance;

  bool _sending = false;
  bool _prefilledFromLead = false;

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

  void _maybePrefillFromLead(PrimeLead? lead) {
    if (lead == null || _prefilledFromLead) {
      return;
    }

    if (_nameCtrl.text.trim().isEmpty && lead.name.isNotEmpty) {
      _nameCtrl.text = lead.name;
    }
    if (_phoneCtrl.text.trim().isEmpty && lead.phone.isNotEmpty) {
      _phoneCtrl.text = lead.phone;
    }
    if (_goalCtrl.text.trim().isEmpty && lead.goal.isNotEmpty) {
      _goalCtrl.text = lead.goal;
    }
    if (_messageCtrl.text.trim().isEmpty && lead.message.isNotEmpty) {
      _messageCtrl.text = lead.message;
    }

    _prefilledFromLead = true;
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
      final repo = ref.read(primeLeadRepositoryProvider);
      final status = await repo.submitLead(
        uid: user.uid,
        email: user.email ?? '',
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        goal: _goalCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );

      if (!mounted) return;
      final goToCoach = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _PrimeLeadSuccessDialog(status: status),
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
    final user = _auth.currentUser;
    final leadAsync = user == null
        ? AsyncValue<PrimeLead?>.data(null)
        : ref.watch(primeLeadProvider(user.uid));
    final lead = leadAsync.asData?.value;

    _maybePrefillFromLead(lead);

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
                if (user != null) ...[
                  _LeadStatusCard(state: leadAsync, lead: lead),
                  const SizedBox(height: 24),
                ],
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

class _LeadStatusCard extends StatelessWidget {
  const _LeadStatusCard({required this.state, required this.lead});

  final AsyncValue<PrimeLead?> state;
  final PrimeLead? lead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (state.isLoading) {
      return Card(
        color: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Cargando el estado de tu solicitud PRIME…',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state.hasError) {
      return const _StatusInfoCard(
        icon: Icons.error_outline,
        title: 'No pudimos cargar tu solicitud',
        message: 'Actualiza la app o vuelve a intentarlo en unos minutos.',
      );
    }

    final leadData = lead;
    if (leadData == null) {
      final copy = primeLeadCopyForStage(PrimeLeadStage.pendingAssignment);
      return _StatusInfoCard(
        icon: Icons.support_agent,
        title: copy.title,
        message: copy.description,
        badge: copy.badge,
        stage: PrimeLeadStage.pendingAssignment,
      );
    }

    final copy = primeLeadCopyForStage(leadData.stage);
    final statusColor = primeLeadStatusColor(leadData.stage);
    final updatedAt = leadData.updatedAt ?? leadData.submittedAt ?? leadData.createdAt;
    final formattedDate = updatedAt != null
        ? DateFormat('dd MMM yyyy · HH:mm', 'es').format(updatedAt.toLocal())
        : null;

    return Card(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _StatusBadge(text: copy.badge, color: statusColor),
                if (formattedDate != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Actualizado $formattedDate',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              copy.title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            if (leadData.goal.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Objetivo principal',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                leadData.goal,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
            if (leadData.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Mensaje para el coach',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                leadData.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusInfoCard extends StatelessWidget {
  const _StatusInfoCard({
    required this.icon,
    required this.title,
    required this.message,
    this.badge,
    this.stage,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? badge;
  final PrimeLeadStage? stage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = stage != null ? primeLeadStatusColor(stage!) : Colors.white70;

    return Card(
      color: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withOpacity(0.15),
                  foregroundColor: badgeColor,
                  child: Icon(icon),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 12),
                  _StatusBadge(text: badge!, color: badgeColor),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _PrimeLeadSuccessDialog extends StatelessWidget {
  const _PrimeLeadSuccessDialog({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final stage = primeLeadStageForStatus(status);
    final copy = primeLeadCopyForStage(stage);
    return AlertDialog(
      backgroundColor: const Color(0xFF111111),
      title: Text(
        primeLeadSuccessTitle(stage),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: Text(
        copy.successMessage,
        style: const TextStyle(color: Colors.white70, height: 1.4),
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

