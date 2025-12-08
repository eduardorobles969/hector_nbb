import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prime_lead.dart';
import '../prime/prime_lead_copy.dart';
import '../prime/prime_lead_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _leadUidCtrl = TextEditingController();
  final _coachUidCtrl = TextEditingController();
  bool _assigning = false;
  String? _statusMessage;

  @override
  void dispose() {
    _leadUidCtrl.dispose();
    _coachUidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leadsAsync = ref.watch(pendingPrimeLeadsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Panel administrador')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gestiona solicitudes PRIME y asigna coaches.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildAssignmentCard(context),
              const SizedBox(height: 24),
              Expanded(
                child: leadsAsync.when(
                  data: (leads) => _PrimeLeadList(
                    leads: leads,
                    onSelectLead: _prefillFromLead,
                    onApprove: _approveLead,
                    onReject: _rejectLead,
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Text('No pudimos cargar las solicitudes: $err'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asignar coach a lead', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _leadUidCtrl,
              decoration: const InputDecoration(
                labelText: 'UID del lead (coloso prime)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _coachUidCtrl,
              decoration: const InputDecoration(labelText: 'UID del coach'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(
                  onPressed: _assigning ? null : () => _assignCoach(context),
                  child: _assigning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Asignar coach'),
                ),
                const SizedBox(width: 12),
                if (_statusMessage != null)
                  Expanded(
                    child: Text(
                      _statusMessage!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: copia los UID desde Firestore o desde el modo debug de la app.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignCoach(BuildContext context) async {
    final leadUid = _leadUidCtrl.text.trim();
    final coachUid = _coachUidCtrl.text.trim();
    if (leadUid.isEmpty || coachUid.isEmpty) {
      setState(() => _statusMessage = 'Ingresa ambos UID antes de asignar.');
      return;
    }

    setState(() {
      _assigning = true;
      _statusMessage = null;
    });

    try {
      final repo = ref.read(primeLeadRepositoryProvider);
      await repo.claimLead(leadUid: leadUid, coachUid: coachUid);
      setState(() {
        _statusMessage = 'Coach asignado correctamente a $leadUid';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al asignar: $e';
      });
    } finally {
      setState(() {
        _assigning = false;
      });
    }
  }

  void _prefillFromLead(PrimeLead lead) {
    setState(() {
      _leadUidCtrl.text = lead.uid;
      if (lead.assignedCoachUid != null) {
        _coachUidCtrl.text = lead.assignedCoachUid!;
      }
    });
  }

  Future<void> _approveLead(PrimeLead lead) async {
    if (_assigning) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _assigning = true;
      _statusMessage = null;
    });
    try {
      final repo = ref.read(primeLeadRepositoryProvider);
      await repo.approveLead(leadUid: lead.uid);
      setState(() {
        _statusMessage =
            'Lead aprobado: ${lead.name.isNotEmpty ? lead.name : lead.uid}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al aprobar: $e';
      });
    } finally {
      setState(() {
        _assigning = false;
      });
    }
  }

  Future<void> _rejectLead(PrimeLead lead) async {
    if (_assigning) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _assigning = true;
      _statusMessage = null;
    });
    try {
      final repo = ref.read(primeLeadRepositoryProvider);
      await repo.rejectLead(leadUid: lead.uid);
      setState(() {
        _statusMessage =
            'Lead rechazado: ${lead.name.isNotEmpty ? lead.name : lead.uid}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al rechazar: $e';
      });
    } finally {
      setState(() {
        _assigning = false;
      });
    }
  }
}

class _PrimeLeadList extends StatelessWidget {
  const _PrimeLeadList({
    required this.leads,
    this.onSelectLead,
    this.onApprove,
    this.onReject,
  });

  final List<PrimeLead> leads;
  final void Function(PrimeLead lead)? onSelectLead;
  final void Function(PrimeLead lead)? onApprove;
  final void Function(PrimeLead lead)? onReject;

  @override
  Widget build(BuildContext context) {
    if (leads.isEmpty) {
      return const Center(
        child: Text('No hay solicitudes pendientes en este momento.'),
      );
    }

    return ListView.separated(
      itemCount: leads.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lead = leads[index];
        final copy = primeLeadCopyForStage(lead.stage);
        return Card(
          child: ListTile(
            onTap: onSelectLead == null ? null : () => onSelectLead!(lead),
            title: Text(lead.name.isNotEmpty ? lead.name : lead.uid),
            subtitle: Text('${lead.email}\n${copy.badge}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'select':
                    onSelectLead?.call(lead);
                    break;
                  case 'approve':
                    onApprove?.call(lead);
                    break;
                  case 'reject':
                    onReject?.call(lead);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Text('Rellenar formulario'),
                ),
                const PopupMenuItem(
                  value: 'approve',
                  child: Text('Aprobar PRIME'),
                ),
                const PopupMenuItem(value: 'reject', child: Text('Rechazar')),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [Text(lead.stage.name), const Icon(Icons.more_vert)],
              ),
            ),
          ),
        );
      },
    );
  }
}
