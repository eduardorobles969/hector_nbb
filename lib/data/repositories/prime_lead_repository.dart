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

  Stream<PrimeLead?> watchLead(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PrimeLead.fromDoc(doc);
    });
  }

  Future<String> submitLead({
    required String uid,
    required String email,
    required String name,
    required String phone,
    required String goal,
    required String message,
    String source = 'app',
  }) async {
    final leadRef = _col.doc(uid);
    final userRef = _db.collection('users').doc(uid);

    var resolvedStatus = 'pending_coach_assignment';

    await _db.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      final existingData = leadSnap.exists ? leadSnap.data() ?? const <String, dynamic>{} : const <String, dynamic>{};
      final existingStatus = (existingData['status'] ?? '') as String?;
      final hasCustomStatus = existingStatus != null &&
          existingStatus.isNotEmpty &&
          existingStatus != 'pending_coach_assignment';

      final nextStatus = hasCustomStatus ? existingStatus! : 'pending_coach_assignment';
      resolvedStatus = nextStatus;

      final hadCreatedAt = existingData.containsKey('createdAt') && existingData['createdAt'] != null;

      tx.set(
        leadRef,
        {
          'uid': uid,
          'email': email,
          'name': name,
          'phone': phone,
          'goal': goal,
          'message': message,
          'source': source,
          'status': nextStatus,
          'submittedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          if (!hadCreatedAt) 'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        userRef,
        {
          'role': 'coloso_prime',
          'roles': FieldValue.arrayUnion(['coloso_prime']),
          'primeStatus': nextStatus,
          'primeActivatedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    return resolvedStatus;
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
