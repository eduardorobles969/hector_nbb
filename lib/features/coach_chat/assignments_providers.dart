import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/assignments_repository.dart';

final assignmentsRepoProvider = Provider<AssignmentsRepository>(
  (ref) => AssignmentsRepository(),
);

// Flujo de usuarios asignados a un coach
final coachUsersProvider = StreamProvider.family<List<String>, String>((
  ref,
  coachUid,
) {
  return ref.watch(assignmentsRepoProvider).watchUsersForCoach(coachUid);
});

// Flujo de coaches asignados a un usuario
final userCoachesProvider = StreamProvider.family<List<String>, String>((
  ref,
  userUid,
) {
  return ref.watch(assignmentsRepoProvider).watchCoachesForUser(userUid);
});
