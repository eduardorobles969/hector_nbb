import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../models/adaptive_plan.dart';
import '../models/user_role.dart';

class PlanRepository {
  PlanRepository();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;
  DocumentReference<Map<String, dynamic>> get _doc =>
      _db.collection('plans').doc(_uid);

  Future<void> ensurePlan() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      final role = await _fetchRole();
      final seed = _seedForRole(role);
      await _doc.set(seed.toMap());
    }
  }

  Stream<AdaptivePlan?> watch() {
    return _doc.snapshots().map(
      (s) => s.exists ? AdaptivePlan.fromMap(s.data()!) : null,
    );
  }

  Future<void> setActionStatus(String actionId, String status) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final plan = AdaptivePlan.fromMap(snap.data()!);
    final updated = plan.today
        .map((a) => a.id == actionId ? a.copyWith(status: status) : a)
        .toList();
    await _doc.update({
      'todayActions': updated.map((e) => e.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> snoozeAction(String actionId) async =>
      setActionStatus(actionId, 'snoozed');
  Future<void> completeAction(String actionId) async =>
      setActionStatus(actionId, 'done');
  Future<void> skipAction(String actionId) async =>
      setActionStatus(actionId, 'skipped');

  Future<UserRole> _fetchRole() async {
    final userDoc = await _db.collection('users').doc(_uid).get();
    if (!userDoc.exists) return UserRole.coloso;
    final data = userDoc.data();
    if (data == null) return UserRole.coloso;
    return UserRoleX.fromId((data['role'] ?? 'coloso') as String);
  }

  AdaptivePlan _seedForRole(UserRole role) {
    final now = DateTime.now();
    return AdaptivePlan(
      uid: _uid,
      goals: _goalsForRole(role),
      today: _actionsForRole(role),
      updatedAt: now,
      lastCoachReviewAt: role == UserRole.coach ? now : null,
    );
  }

  List<String> _goalsForRole(UserRole role) {
    switch (role) {
      case UserRole.coach:
        return [
          'Guiar a tres colosos en sesiones de foco',
          'Revisar planes activos y ajustar cargas',
          'Cuidar el propio entrenamiento y energia',
        ];
      case UserRole.colosoPrime:
        return [
          'Construir fuerza y movilidad sostenida',
          'Dominar rituales de respiracion y registro',
          'Refinar alimentacion segun senales internas',
        ];
      case UserRole.coloso:
        return [
          'Reconectar con senales internas',
          'Mantener movimiento disfrutable diario',
          'Bajar autoexigencia y ganar confianza',
        ];
    }
  }

  List<DailyAction> _actionsForRole(UserRole role) {
    switch (role) {
      case UserRole.coach:
        return [
          DailyAction(
            id: _uuid.v4(),
            title: 'Revisar tablon de colosos',
            note: 'Detecta bloqueos y prepara mensajes',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Enviar ritual personalizado',
            note: 'Refuerza habitos segun progreso del dia',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Practica tu propio ritual',
            note: 'Modelo de disciplina antes de dormir',
          ),
        ];
      case UserRole.colosoPrime:
        return [
          DailyAction(
            id: _uuid.v4(),
            title: 'Respira 4-7-8 despues de cada comida',
            note: 'Sintoniza hambre y saciedad con calma',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Entrena fuerza 20 min',
            note: 'Usa lastre progresivo o peso corporal',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Registrar victorias y obstaculos',
            note: 'Escribe 3 lineas en el diario antes de dormir',
          ),
        ];
      case UserRole.coloso:
        return [
          DailyAction(
            id: _uuid.v4(),
            title: 'Respira 2 min tras comer',
            note: 'Observa saciedad sin juicio',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Caminar 10 min con musica',
            note: 'Honra el movimiento sencillo',
          ),
          DailyAction(
            id: _uuid.v4(),
            title: 'Escribe una gratitud',
            note: 'Cierra el dia celebrando progreso',
          ),
        ];
    }
  }
}
