import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final DateTime occurredAt;
  final List<String> sensations; // ej: ["satisfecho","energizado"]
  final int hungerSatiety; // 1..5
  final int energy; // 1..5
  final String contextText;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry({
    required this.id,
    required this.occurredAt,
    required this.sensations,
    required this.hungerSatiety,
    required this.energy,
    required this.contextText,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'occurredAt': Timestamp.fromDate(occurredAt),
    'sensations': sensations,
    'hungerSatiety': hungerSatiety,
    'energy': energy,
    'contextText': contextText,
    'photoUrl': photoUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  static JournalEntry fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return JournalEntry(
      id: d['id'],
      occurredAt: (d['occurredAt'] as Timestamp).toDate(),
      sensations: List<String>.from(d['sensations'] ?? []),
      hungerSatiety: d['hungerSatiety'] ?? 3,
      energy: d['energy'] ?? 3,
      contextText: d['contextText'] ?? '',
      photoUrl: d['photoUrl'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }
}
