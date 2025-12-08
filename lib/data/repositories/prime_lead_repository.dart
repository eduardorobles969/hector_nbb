import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prime_lead.dart';

class PrimeLeadRepository {
  PrimeLeadRepository();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('prime_leads');

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
      final existingData = leadSnap.exists
          ? leadSnap.data() ?? const <String, dynamic>{}
          : const <String, dynamic>{};
      final existingStatus = (existingData['status'] ?? '') as String?;
      final hasCustomStatus =
          existingStatus != null &&
          existingStatus.isNotEmpty &&
          existingStatus != 'pending_coach_assignment';

      final nextStatus = hasCustomStatus
          ? existingStatus!
          : 'pending_coach_assignment';
      resolvedStatus = nextStatus;

      final hadCreatedAt =
          existingData.containsKey('createdAt') &&
          existingData['createdAt'] != null;

      final userSnap = await tx.get(userRef);
      final roles = _resolvedRoles(userSnap.data(), add: 'coloso');
      final primaryRole = _canonicalRole(roles);

      tx.set(leadRef, {
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
      }, SetOptions(merge: true));

      tx.set(userRef, {
        'role': primaryRole,
        'roles': roles.toList(),
        'primeStatus': nextStatus,
        'primeIntentAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    return resolvedStatus;
  }

  Future<void> approveLead({required String leadUid}) async {
    final leadRef = _col.doc(leadUid);
    final userRef = _db.collection('users').doc(leadUid);

    await _db.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      if (!leadSnap.exists) {
        throw StateError('La solicitud ya no est disponible.');
      }
      final userSnap = await tx.get(userRef);

      final roles = _resolvedRoles(userSnap.data(), add: 'coloso_prime');
      final primaryRole = _canonicalRole(roles, fallback: 'coloso_prime');

      tx.set(leadRef, {
        'status': 'pending_coach_assignment',
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.set(userRef, {
        'role': primaryRole,
        'roles': roles.toList(),
        'primeStatus': 'pending_coach_assignment',
        'primeActivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> claimLead({
    required String leadUid,
    required String coachUid,
  }) async {
    final leadRef = _col.doc(leadUid);
    final assignmentRef = _db
        .collection('assignments')
        .doc(leadUid)
        .collection('coaches')
        .doc(coachUid);
    final userRef = _db.collection('users').doc(leadUid);
    final coachRef = _db.collection('users').doc(coachUid);

    await _db.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      if (!leadSnap.exists) {
        throw StateError('La solicitud ya no est disponible.');
      }
      final data = leadSnap.data()!;
      final status = (data['status'] ?? '') as String;
      if (status != 'pending_coach_assignment') {
        throw StateError('Esta solicitud ya fue tomada por otro coach.');
      }

      final userSnap = await tx.get(userRef);
      final coachSnap = await tx.get(coachRef);
      await tx.get(assignmentRef);

      tx.update(leadRef, {
        'status': 'coach_assigned',
        'assignedCoachUid': coachUid,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(assignmentRef, {
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      }, SetOptions(merge: true));

      final roles = _resolvedRoles(userSnap.data(), add: 'coloso_prime');
      roles.add('coloso');
      final primaryRole = _canonicalRole(roles, fallback: 'coloso_prime');

      tx.set(userRef, {
        'role': primaryRole,
        'roles': roles.toList(),
        'primeStatus': 'coach_assigned',
        'primeActivatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final coachRoles = _resolvedRoles(coachSnap.data(), add: 'coach');
      final coachPrimaryRole = _canonicalRole(coachRoles, fallback: 'coach');

      tx.set(coachRef, {
        'role': coachPrimaryRole,
        'roles': coachRoles.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> rejectLead({required String leadUid, String? reason}) async {
    final leadRef = _col.doc(leadUid);
    final userRef = _db.collection('users').doc(leadUid);

    await _db.runTransaction((tx) async {
      final leadSnap = await tx.get(leadRef);
      if (!leadSnap.exists) {
        throw StateError('La solicitud ya no est disponible.');
      }
      final userSnap = await tx.get(userRef);

      tx.set(leadRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final roles = _resolvedRoles(userSnap.data(), remove: 'coloso_prime');
      roles.add('coloso');
      final primaryRole = _canonicalRole(roles);

      tx.set(userRef, {
        'role': primaryRole,
        'roles': roles.toList(),
        'primeStatus': 'rejected',
        'primeActivatedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Set<String> _resolvedRoles(
    Map<String, dynamic>? data, {
    String? add,
    String? remove,
  }) {
    final roles = <String>{};
    final rolesField = data?['roles'];
    if (rolesField is Iterable) {
      for (final value in rolesField) {
        if (value is String && value.isNotEmpty) {
          roles.add(value.trim().toLowerCase());
        }
      }
    }
    final singleRole = (data?['role'] as String?)?.trim().toLowerCase();
    if (singleRole != null && singleRole.isNotEmpty) {
      roles.add(singleRole);
    }
    if (remove != null && remove.isNotEmpty) {
      roles.remove(remove);
    }
    if (add != null && add.isNotEmpty) {
      roles.add(add);
    }
    return roles;
  }

  String _canonicalRole(Set<String> roles, {String fallback = 'coloso'}) {
    if (roles.contains('admin')) return 'admin';
    if (roles.contains('coloso_prime')) return 'coloso_prime';
    if (roles.contains('coach')) return 'coach';
    return fallback;
  }
}
