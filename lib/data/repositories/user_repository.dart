import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';
import '../../config/app_roles.dart';

class UserRepository {
  UserRepository();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Stream<UserProfile?> watchProfile(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromDoc(doc);
    });
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromDoc(doc);
  }

  Future<void> ensureUserDocument(
    User user, {
    UserRole defaultRole = UserRole.coloso,
  }) async {
    final ref = _col.doc(user.uid);
    final snap = await ref.get();
    final baseData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL ?? '',
      'active': true,
      'lastSignInAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final normalizedEmail = user.email?.trim().toLowerCase();
    final forcedRole =
        normalizedEmail != null && adminAccessEmails.contains(normalizedEmail)
        ? UserRole.admin
        : null;
    final effectiveRole = forcedRole ?? defaultRole;
    final effectiveRoleId = effectiveRole.id;

    final existingData = snap.data();

    final initialRoles = <String>{effectiveRoleId};
    if (forcedRole == UserRole.admin) {
      initialRoles.add('coach');
    }

    if (!snap.exists) {
      await ref.set({
        ...baseData,
        'role': effectiveRoleId,
        'roles': initialRoles.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingComplete': false,
        'goals': <String>[],
        'aiQuotaRemaining': effectiveRole == UserRole.coloso ? 3 : -1,
      });
      return;
    }

    var storedRoleId = (existingData?['role'] as String?)?.trim().toLowerCase();
    if (storedRoleId == null || storedRoleId.isEmpty) {
      storedRoleId = effectiveRoleId;
    }
    if (forcedRole != null) {
      storedRoleId = forcedRole.id;
    }

    final rolesField = existingData?['roles'];
    final storedRoles = <String>{};
    if (rolesField is Iterable) {
      for (final value in rolesField) {
        if (value is String && value.isNotEmpty) {
          storedRoles.add(value.trim().toLowerCase());
        }
      }
    }
    storedRoles.addAll(initialRoles);

    final goalsField = existingData?['goals'];
    final goalsList = goalsField is Iterable
        ? goalsField.whereType<String>().toList()
        : <String>[];

    final aiQuota = existingData?['aiQuotaRemaining'];
    final quotaValue = aiQuota is num
        ? aiQuota.toInt()
        : (storedRoleId == UserRole.coloso.id ? 3 : -1);

    await ref.set({
      ...baseData,
      'role': storedRoleId,
      'roles': storedRoles.toList(),
      'createdAt': existingData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'onboardingComplete': existingData?['onboardingComplete'] ?? false,
      'goals': goalsList,
      'aiQuotaRemaining': quotaValue,
    }, SetOptions(merge: true));
  }

  Future<UserRole> getRole(String uid) async {
    final doc = await _col.doc(uid).get();
    if (!doc.exists) return UserRole.coloso;
    final data = doc.data();
    if (data == null) return UserRole.coloso;
    return UserRoleX.fromId((data['role'] ?? 'coloso') as String);
  }

  Future<void> updateRole(String uid, UserRole role) async {
    await _col.doc(uid).update({
      'role': role.id,
      'roles': FieldValue.arrayUnion([role.id]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveOnboardingIntake(
    String uid, {
    required Map<String, dynamic> answers,
  }) async {
    final doc = _col.doc(uid);
    final payload = {
      'displayName': answers['displayName'] ?? '',
      'email': answers['email'] ?? '',
      'fitnessLevel': answers['fitnessLevel'],
      'goals': answers['goals'] ?? <String>[],
      'gender': answers['gender'],
      'heightCm': int.tryParse('${answers['heightCm']}'),
      'weightKg': int.tryParse('${answers['weightKg']}'),
      'pullups': answers['pullups'],
      'pushups': answers['pushups'],
      'squats': answers['squats'],
      'dips': answers['dips'],
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(payload, SetOptions(merge: true));
    await _db.collection('user_intake').doc(uid).set({
      'uid': uid,
      ...answers,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
