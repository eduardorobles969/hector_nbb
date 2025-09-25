import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prime_lead.dart';

class PrimeLeadRepository {
  PrimeLeadRepository();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('prime_leads');

  Stream<List<PrimeLead>> watchPendingLeads() {
    return _col
        .where('status', isEqualTo: 'pending_coach_assignment')
        .snapshots()
        .map((snap) => snap.docs.map(PrimeLead.fromDoc).toList());
  }

  Future<void> claimLead({
    required String leadUid,
    required String coachUid,
  }) async {
    final leadRef = _col.doc(leadUid);
    final assignmentRef =
        _db.collection('assignments').doc(leadUid).collection('coaches').doc(coachUid);
    final userRef = _db.collection('users').doc(leadUid);

    await _db.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      if (!leadSnap.exists) {
        throw StateError('La solicitud ya no está disponible.');
      }
      final data = leadSnap.data()!;
      final status = (data['status'] ?? '') as String;
      if (status != 'pending_coach_assignment') {
        throw StateError('Esta solicitud ya fue tomada por otro coach.');
      }

      tx.update(leadRef, {
        'status': 'coach_assigned',
        'assignedCoachUid': coachUid,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(
        assignmentRef,
        {
          'assignedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        },
        SetOptions(merge: true),
      );

      tx.set(
        userRef,
        {
          'role': 'coloso_prime',
          'roles': FieldValue.arrayUnion(['coloso_prime']),
          'primeStatus': 'coach_assigned',
          'primeActivatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
