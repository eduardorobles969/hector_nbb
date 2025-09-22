import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository.dart';

final chatRepoProvider = Provider<ChatRepository>((ref) => ChatRepository());

final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  otherUid,
) {
  return ref.watch(chatRepoProvider).watchMessages(otherUid);
});
