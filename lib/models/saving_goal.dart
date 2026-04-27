import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;
  final String category;
  final String emoji;
  final DateTime? createdAt;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
    required this.category,
    this.emoji = '🎯',
    this.createdAt,
  });

  factory SavingGoal.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavingGoal(
      id: doc.id,
      title: data['title'] ?? '',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      targetDate:
          (data['targetDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 365)),
      category: data['category'] ?? 'General',
      emoji: data['emoji'] ?? '🎯',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': Timestamp.fromDate(targetDate),
      'category': category,
      'emoji': emoji,
    };
  }

  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? emoji,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }

  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining =>
      (targetAmount - currentAmount).clamp(0, double.infinity);
  int get daysLeft => targetDate.difference(DateTime.now()).inDays;
}
