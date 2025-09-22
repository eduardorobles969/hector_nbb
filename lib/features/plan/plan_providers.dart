import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/models/adaptive_plan.dart';

final planRepoProvider = Provider<PlanRepository>((_) => PlanRepository());

final planStreamProvider = StreamProvider<AdaptivePlan?>((ref) {
  return ref.watch(planRepoProvider).watch();
});
