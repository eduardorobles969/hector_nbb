import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentsRepository {
  final _db = FirebaseFirestore.instance;

  // Lista de usuarios asignados a un coach
  Stream<List<String>> watchUsersForCoach(String coachUid) {
    return _db
        .collectionGroup('coaches')
        .where(FieldPath.documentId, isEqualTo: coachUid)
        .snapshots()
        .map((snap) {
          final users = snap.docs
              .map((doc) => doc.reference.parent.parent?.id)
              .whereType<String>()
              .toSet()
              .toList();
          users.sort();
          return users;
        });
  }

  // Lista de coaches de un usuario
  Stream<List<String>> watchCoachesForUser(String userUid) {
    return _db
        .collection('assignments')
        .doc(userUid)
        .collection('coaches')
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toList());
  }
}
