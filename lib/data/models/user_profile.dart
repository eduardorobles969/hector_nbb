import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

class UserProfile {
  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.active,
    this.createdAt,
    this.updatedAt,
    this.lastSignInAt,
    this.onboardingComplete = false,
    this.fitnessLevel,
    this.goals = const [],
    this.gender,
    this.heightCm,
    this.weightKg,
    this.pullupsRange,
    this.pushupsRange,
    this.squatsRange,
    this.dipsRange,
  });

  final String uid;
  final String email;
  final String displayName;
  final String photoUrl;
  final UserRole role;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSignInAt;
  final bool onboardingComplete;
  final String? fitnessLevel;
  final List<String> goals;
  final String? gender;
  final int? heightCm;
  final int? weightKg;
  final String? pullupsRange;
  final String? pushupsRange;
  final String? squatsRange;
  final String? dipsRange;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('User profile missing for uid ');
    }
    final primaryRole = _primaryRoleFromData(data);

    return UserProfile(
      uid: doc.id,
      email: (data['email'] ?? '') as String,
      displayName: (data['displayName'] ?? '') as String,
      photoUrl: (data['photoURL'] ?? '') as String,
      role: UserRoleX.fromId(primaryRole),
      active: (data['active'] ?? true) as bool,
      createdAt: _fromTimestamp(data['createdAt']),
      updatedAt: _fromTimestamp(data['updatedAt']),
      lastSignInAt: _fromTimestamp(data['lastSignInAt']),
      onboardingComplete: (data['onboardingComplete'] ?? false) as bool,
      fitnessLevel: data['fitnessLevel'] as String?,
      goals: List<String>.from(data['goals'] ?? const <String>[]),
      gender: data['gender'] as String?,
      heightCm: (data['heightCm'] as num?)?.toInt(),
      weightKg: (data['weightKg'] as num?)?.toInt(),
      pullupsRange: data['pullups'] as String?,
      pushupsRange: data['pushups'] as String?,
      squatsRange: data['squats'] as String?,
      dipsRange: data['dips'] as String?,
    );
  }

  static DateTime? _fromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static String _primaryRoleFromData(Map<String, dynamic> data) {
    final rawRole = data['role'];
    if (rawRole is String && rawRole.trim().isNotEmpty) {
      return rawRole;
    }

    final rolesField = data['roles'];
    if (rolesField is Iterable) {
      final normalizedRoles = rolesField
          .whereType<String>()
          .map((role) => role.trim().toLowerCase())
          .where((role) => role.isNotEmpty)
          .toSet();

      if (normalizedRoles.contains('coach')) {
        return 'coach';
      }
      if (normalizedRoles.contains('coloso_prime') ||
          normalizedRoles.contains('colosoprime') ||
          normalizedRoles.contains('coloso-prime')) {
        return 'coloso_prime';
      }
    }

    return 'coloso';
  }
}
