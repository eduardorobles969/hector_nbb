import 'package:cloud_firestore/cloud_firestore.dart';

class PrimeLead {
  PrimeLead({
    required this.uid,
    required this.status,
    required this.name,
    required this.email,
    required this.phone,
    required this.goal,
    required this.message,
    required this.source,
    this.assignedCoachUid,
    this.createdAt,
    this.submittedAt,
    this.updatedAt,
    this.assignedAt,
  });

  final String uid;
  final String status;
  final String name;
  final String email;
  final String phone;
  final String goal;
  final String message;
  final String source;
  final String? assignedCoachUid;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final DateTime? assignedAt;

  PrimeLeadStage get stage => _stageForStatus(status);

  factory PrimeLead.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PrimeLead(
      uid: doc.id,
      status: (data['status'] ?? '') as String,
      name: (data['name'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      phone: (data['phone'] ?? '') as String,
      goal: (data['goal'] ?? '') as String,
      message: (data['message'] ?? '') as String,
      source: (data['source'] ?? '') as String,
      assignedCoachUid: data['assignedCoachUid'] as String?,
      createdAt: _fromTimestamp(data['createdAt']),
      submittedAt: _fromTimestamp(data['submittedAt']),
      updatedAt: _fromTimestamp(data['updatedAt']),
      assignedAt: _fromTimestamp(data['assignedAt']),
    );
  }

  static DateTime? _fromTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

enum PrimeLeadStage {
  pendingAssignment,
  coachAssigned,
  inProgress,
  conversionComplete,
  unknown,
}

PrimeLeadStage _stageForStatus(String status) {
  switch (status) {
    case 'pending_coach_assignment':
      return PrimeLeadStage.pendingAssignment;
    case 'coach_assigned':
      return PrimeLeadStage.coachAssigned;
    case 'converted':
    case 'subscription_activated':
      return PrimeLeadStage.conversionComplete;
    case 'onboarding_call_scheduled':
    case 'awaiting_payment':
    case 'payment_pending':
    case 'follow_up':
    case 'contacted':
      return PrimeLeadStage.inProgress;
    default:
      return PrimeLeadStage.unknown;
  }
}
