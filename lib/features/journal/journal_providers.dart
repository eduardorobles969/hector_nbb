import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/models/journal_entry.dart';

final journalRepoProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

final journalStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  return ref.watch(journalRepoProvider).watchLatest();
});
