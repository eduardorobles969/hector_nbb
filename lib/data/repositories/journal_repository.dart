import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/journal_entry.dart';

class JournalRepository {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  String get _uid => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('journal').doc(_uid).collection('entries');

  Stream<List<JournalEntry>> watchLatest({int limit = 50}) {
    return _col
        .orderBy('occurredAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(JournalEntry.fromDoc).toList());
  }

  Future<String?> _uploadPhoto(String entryId, File file) async {
    final path = 'uploads/$_uid/journal/$entryId/photo.jpg';
    final ref = _storage.ref().child(path);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> createEntry({
    required DateTime occurredAt,
    required List<String> sensations,
    required int hungerSatiety,
    required int energy,
    required String contextText,
    File? photoFile,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    String? photoUrl;
    if (photoFile != null) {
      photoUrl = await _uploadPhoto(id, photoFile);
    }

    final entry = JournalEntry(
      id: id,
      occurredAt: occurredAt,
      sensations: sensations,
      hungerSatiety: hungerSatiety,
      energy: energy,
      contextText: contextText,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
    );

    await _col.doc(id).set(entry.toMap());
  }
}
