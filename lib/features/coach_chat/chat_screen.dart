import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/chat_repository.dart';
import 'chat_providers.dart';
import '../profile/profile_providers.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
  });
  final String otherUid;
  final String otherName;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _initializingThread = true;
  String? _threadInitError;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _prepareThread();
  }

  Future<void> _prepareThread() async {
    setState(() {
      _initializingThread = true;
      _threadInitError = null;
    });
    try {
      await ref.read(chatRepoProvider).ensureThread(widget.otherUid);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        _threadInitError = e.message ?? 'No se pudo inicializar el chat.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _threadInitError = 'No se pudo inicializar el chat.';
      });
    } finally {
      if (mounted) {
        setState(() => _initializingThread = false);
      }
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(chatRepoProvider).sendText(widget.otherUid, text);
      _ctrl.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showError(e.message ?? 'No se pudo enviar el mensaje.');
    } catch (_) {
      if (!mounted) return;
      _showError('No se pudo enviar el mensaje.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherProfileAsync = ref.watch(userProfileProvider(widget.otherUid));
    final rawProfileName = otherProfileAsync.asData?.value?.displayName;
    final profileName = rawProfileName?.trim();
    final otherName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : widget.otherName;
    final shouldWatchMessages =
        !_initializingThread && _threadInitError == null;
    final msgsAsync = shouldWatchMessages
        ? ref.watch(messagesProvider(widget.otherUid))
        : null;

    return Scaffold(
      appBar: AppBar(title: Text('Coach <-> $otherName')),
      body: Column(
        children: [
          Expanded(child: _buildMessages(context, msgsAsync)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje empatico...',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    child: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages(
    BuildContext context,
    AsyncValue<List<ChatMessage>>? msgsAsync,
  ) {
    if (_initializingThread) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threadInitError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_threadInitError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _prepareThread,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (msgsAsync == null) {
      return const SizedBox.shrink();
    }

    return msgsAsync.when(
      data: (items) => ListView.builder(
        reverse: true,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final m = items[i];
          final isMine = ref.read(chatRepoProvider).myUid == m.fromUid;
          return Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMine
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(m.text),
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
