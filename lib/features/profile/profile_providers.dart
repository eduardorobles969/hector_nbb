import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../auth/auth_providers.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.when(
    data: (user) {
      if (user == null) {
        return Stream<UserProfile?>.value(null);
      }
      final repo = ref.watch(userRepositoryProvider);
      return repo.watchProfile(user.uid);
    },
    loading: () => Stream<UserProfile?>.value(null),
    error: (_, __) => Stream<UserProfile?>.value(null),
  );
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((ref, uid) {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchProfile(uid);
});
