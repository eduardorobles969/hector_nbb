import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';
import '../models/user_role.dart';

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
    if (!snap.exists) {
      await ref.set({
        ...baseData,
        'role': defaultRole.id,
        'createdAt': FieldValue.serverTimestamp(),
        'onboardingComplete': false,
        'goals': <String>[],
      });
    } else {
      await ref.set({
        ...baseData,
        'role': snap.data()?['role'] ?? defaultRole.id,
        'createdAt': snap.data()?['createdAt'] ?? FieldValue.serverTimestamp(),
        'onboardingComplete': snap.data()?['onboardingComplete'] ?? false,
        'goals': snap.data()?['goals'] ?? <String>[],
      }, SetOptions(merge: true));
    }
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
