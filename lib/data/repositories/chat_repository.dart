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
    final ref = _db.collection('coachThreads').doc(tid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'members': [myUid, otherUid],
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': '',
      });
    }
    return tid;
  }

  Stream<List<ChatMessage>> watchMessages(String otherUid, {int limit = 200}) {
    final tid = buildThreadId(myUid, otherUid);
    return _db
        .collection('coachThreads')
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
        .collection('coachThreads')
        .doc(tid)
        .collection('messages')
        .doc();
    final now = DateTime.now();

    await _db.runTransaction((tx) async {
      tx.set(msgRef, {
        'fromUid': myUid,
        'text': text,
        'imageUrl': null,
        'sentAt': Timestamp.fromDate(now),
        'readBy': [myUid],
      });
      tx.update(_db.collection('coachThreads').doc(tid), {
        'lastMessageAt': Timestamp.fromDate(now),
        'lastMessagePreview': text.substring(0, text.length.clamp(0, 64)),
      });
    });
  }
}
