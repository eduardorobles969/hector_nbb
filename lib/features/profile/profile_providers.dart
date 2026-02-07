import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../data/models/user_role.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final repo = ref.watch(userRepositoryProvider);
  return auth.idTokenChanges().asyncExpand((user) async* {
    if (user == null) {
      yield null;
      return;
    }
    await repo.ensureUserDocument(user, defaultRole: UserRole.coloso);
    yield* repo.watchProfile(user.uid);
  });
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchProfile(uid);
});
