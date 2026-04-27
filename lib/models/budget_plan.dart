import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetPlan {
  BudgetPlan({
    required this.id,
    required this.title,
    required this.category,
    required this.allocatedAmount,
    required this.notes,
    required this.monthKey,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final double allocatedAmount;
  final String notes;
  final String monthKey;
  final DateTime? createdAt;

  factory BudgetPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetPlan(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'General',
      allocatedAmount: (data['allocatedAmount'] ?? 0).toDouble(),
      notes: data['notes'] ?? '',
      monthKey: data['monthKey'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'allocatedAmount': allocatedAmount,
      'notes': notes,
      'monthKey': monthKey,
    };
  }
}
