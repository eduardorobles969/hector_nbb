import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/thread_id.dart';

class ChatMessage {
  final String id;
  final String fromUid;
  final String text;
  final String? imageUrl;
  final DateTime sentAt;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.fromUid,
    required this.text,
    this.imageUrl,
    required this.sentAt,
    required this.readBy,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    return ChatMessage(
      id: d.id,
      fromUid: m['fromUid'],
      text: m['text'] ?? '',
      imageUrl: m['imageUrl'],
      sentAt: (m['sentAt'] as Timestamp).toDate(),
      readBy: List<String>.from(m['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'text': text,
    'imageUrl': imageUrl,
    'sentAt': Timestamp.fromDate(sentAt),
    'readBy': readBy,
  };
}

class ChatRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  String get myUid => _auth.currentUser!.uid;

  /// Crea/retorna el ID del hilo entre el usuario actual y `otherUid`
  Future<String> ensureThread(String otherUid) async {
    final tid = buildThreadId(myUid, otherUid);
    final members = myUid.compareTo(otherUid) <= 0
        ? <String>[myUid, otherUid]
        : <String>[otherUid, myUid];
    final ref = _db.collection('coach_threads').doc(tid);
    await ref.set({'members': members}, SetOptions(merge: true));
    return tid;
  }

  Stream<List<ChatMessage>> watchMessages(
    String otherUid, {
    int limit = 200,
  }) async* {
    final tid = await ensureThread(otherUid);
    yield* _db
        .collection('coach_threads')
        .doc(tid)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(ChatMessage.fromDoc).toList());
  }

  Future<void> sendText(String otherUid, String text) async {
    final tid = await ensureThread(otherUid);
    final msgRef = _db
        .collection('coach_threads')
        .doc(tid)
        .collection('messages')
        .doc();
    final now = DateTime.now();
    final preview = text.length > 64 ? '${text.substring(0, 64)}...' : text;

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'fromUid': myUid,
        'text': text,
        'imageUrl': null,
        'sentAt': Timestamp.fromDate(now),
        'readBy': [myUid],
      });
      tx.update(_db.collection('coach_threads').doc(tid), {
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessagePreview': preview,
      });
    });
  }
}
