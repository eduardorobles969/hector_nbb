import 'package:cloud_firestore/cloud_firestore.dart';

class DailyAction {
  final String id;
  final String title; // p.ej. "Caminar 10 min con musica"
  final String note; // contexto amable
  final String status; // 'todo' | 'done' | 'skipped' | 'snoozed'

  DailyAction({
    required this.id,
    required this.title,
    required this.note,
    this.status = 'todo',
  });

  factory DailyAction.fromMap(Map<String, dynamic> m) => DailyAction(
        id: m['id'],
        title: m['title'],
        note: m['note'] ?? '',
        status: m['status'] ?? 'todo',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'note': note,
        'status': status,
      };

  DailyAction copyWith({String? status}) => DailyAction(
        id: id,
        title: title,
        note: note,
        status: status ?? this.status,
      );
}

class AdaptivePlan {
  final String uid;
  final List<String> goals; // metas en lenguaje humano
  final List<DailyAction> today; // max 3
  final DateTime? lastCoachReviewAt;
  final DateTime updatedAt;

  AdaptivePlan({
    required this.uid,
    required this.goals,
    required this.today,
    required this.updatedAt,
    this.lastCoachReviewAt,
  });

  factory AdaptivePlan.fromMap(Map<String, dynamic> m) => AdaptivePlan(
        uid: m['uid'],
        goals: List<String>.from(m['goals'] ?? []),
        today: (m['todayActions'] as List<dynamic>? ?? [])
            .map((e) => DailyAction.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        lastCoachReviewAt: m['lastCoachReviewAt'] == null
            ? null
            : (m['lastCoachReviewAt'] as Timestamp).toDate(),
        updatedAt: (m['updatedAt'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'goals': goals,
        'todayActions': today.map((e) => e.toMap()).toList(),
        'lastCoachReviewAt': lastCoachReviewAt == null
            ? null
            : Timestamp.fromDate(lastCoachReviewAt!),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}
