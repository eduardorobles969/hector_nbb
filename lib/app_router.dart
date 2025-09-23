import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/auth_providers.dart';
import 'features/auth/auth_screen.dart';
import 'features/coach_chat/coach_screen.dart';
import 'features/community/community_screen.dart';
import 'features/home/home_shell.dart';
import 'features/journal/journal_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/plan/plan_screen.dart';
import 'features/profile/profile_providers.dart';
import 'features/profile/profile_screen.dart';
import 'features/prime/prime_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/welcome/welcome_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final profileState = ref.watch(currentUserProfileProvider);
  final auth = ref.watch(firebaseAuthProvider);

  bool needsOnboarding() {
    return profileState.maybeWhen(
      data: (profile) => profile?.onboardingComplete != true,
      orElse: () => false,
    );
  }

  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => HomeShell(child: child),
        routes: [
          GoRoute(path: '/plan', builder: (_, __) => const PlanScreen()),
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/coach', builder: (_, __) => const CoachScreen()),
          GoRoute(
            path: '/community',
            builder: (_, __) => const CommunityScreen(),
          ),
          GoRoute(path: '/prime', builder: (_, __) => const PrimeScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
    redirect: (ctx, state) {
      final isSplashRoute = state.uri.path == '/';
      final isAuthRoute = state.uri.path == '/auth';
      final isWelcomeRoute = state.uri.path == '/welcome';
      final isOnboardingRoute = state.uri.path == '/onboarding';

      if (authState.isLoading) {
        return null;
      }

      final user = authState.asData?.value;

      if (user == null) {
        if (isAuthRoute || isSplashRoute || isWelcomeRoute || isOnboardingRoute) {
          return null;
        }
        return '/welcome';
      }

      final shouldOnboard = needsOnboarding();
      if (shouldOnboard && !isOnboardingRoute) {
        return '/onboarding';
      }
      if (!shouldOnboard && isOnboardingRoute) {
        return '/profile';
      }
      if (isWelcomeRoute) {
        return shouldOnboard ? '/onboarding' : '/profile';
      }
      if (isAuthRoute) {
        return shouldOnboard ? '/onboarding' : '/profile';
      }

      return null;
    },
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
