import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prime_lead.dart';
import '../../data/repositories/prime_lead_repository.dart';

final primeLeadRepositoryProvider = Provider<PrimeLeadRepository>((ref) {
  return PrimeLeadRepository();
});

final pendingPrimeLeadsProvider = StreamProvider<List<PrimeLead>>((ref) {
  return ref.watch(primeLeadRepositoryProvider).watchPendingLeads();
});
