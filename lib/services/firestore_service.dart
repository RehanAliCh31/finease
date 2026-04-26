import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // --------------- Transactions ---------------

  Stream<List<FinancialTransaction>> getTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => FinancialTransaction.fromFirestore(doc)).toList());
  }

  Future<void> addTransaction(FinancialTransaction transaction) {
    return _db.collection('users').doc(uid).collection('transactions').add(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) {
    return _db.collection('users').doc(uid).collection('transactions').doc(id).delete();
  }

  // --------------- Saving Goals ---------------

  Stream<List<SavingGoal>> getSavingGoals() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavingGoal.fromFirestore(doc)).toList());
  }

  Future<void> addSavingGoal(SavingGoal goal) {
    final map = goal.toMap();
    map['createdAt'] = FieldValue.serverTimestamp();
    return _db.collection('users').doc(uid).collection('saving_goals').add(map);
  }

  Future<void> updateSavingGoal(String goalId, Map<String, dynamic> data) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .update(data);
  }

  Future<void> deleteSavingGoal(String goalId) {
    return _db.collection('users').doc(uid).collection('saving_goals').doc(goalId).delete();
  }

  Future<void> addContribution(String goalId, double amount) async {
    final goalRef = _db.collection('users').doc(uid).collection('saving_goals').doc(goalId);
    final doc = await goalRef.get();
    if (!doc.exists) return;
    final current = (doc.data()?['currentAmount'] ?? 0.0).toDouble();
    final updated = current + amount;

    await goalRef.update({'currentAmount': updated});

    // Log the contribution
    await goalRef.collection('contributions').add({
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getContributions(String goalId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'amount': (data['amount'] ?? 0).toDouble(),
                'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
              };
            }).toList());
  }

  // --------------- Course Progress ---------------

  Future<void> saveCourseProgress(String courseId, int completedLessons, int totalLessons) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('course_progress')
        .doc(courseId)
        .set({
      'completedLessons': completedLessons,
      'totalLessons': totalLessons,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getCourseProgress(String courseId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('course_progress')
        .doc(courseId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> saveQuizScore(String courseId, String quizId, int score, int total) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_scores')
        .doc('${courseId}_$quizId')
        .set({
      'score': score,
      'total': total,
      'percentage': ((score / total) * 100).round(),
      'date': FieldValue.serverTimestamp(),
    });
  }

  // --------------- User Profile ---------------

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getUserProfile() {
    return _db.collection('users').doc(uid).snapshots().map((doc) => doc.data() ?? {});
  }
}
