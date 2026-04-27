import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/demo_finance_data.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  Future<void> ensureSeedData() async {
    final userRef = _db.collection('users').doc(uid);
    final transactionsRef = userRef.collection('transactions');
    final goalsRef = userRef.collection('saving_goals');
    final profileRef = userRef;

    final existingTransactions = await transactionsRef.limit(1).get();
    if (existingTransactions.docs.isEmpty) {
      final batch = _db.batch();
      for (final transaction in DemoFinanceData.sampleTransactions()) {
        final doc = transactionsRef.doc();
        batch.set(doc, transaction.toMap());
      }
      await batch.commit();
    }

    final existingGoals = await goalsRef.limit(1).get();
    if (existingGoals.docs.isEmpty) {
      final batch = _db.batch();
      for (final goal in DemoFinanceData.sampleGoals()) {
        final doc = goalsRef.doc();
        final map = goal.toMap();
        map['createdAt'] = FieldValue.serverTimestamp();
        batch.set(doc, map);
      }
      await batch.commit();
    }

    final profile = await profileRef.get();
    if (!profile.exists ||
        !(profile.data()?.containsKey('fullName') ?? false)) {
      await profileRef.set(
        DemoFinanceData.sampleProfile,
        SetOptions(merge: true),
      );
    }
  }

  // --------------- Transactions ---------------

  Stream<List<FinancialTransaction>> getTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinancialTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> addTransaction(FinancialTransaction transaction) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(transaction.toMap());
  }

  Future<void> deleteTransaction(String id) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  // --------------- Saving Goals ---------------

  Stream<List<SavingGoal>> getSavingGoals() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SavingGoal.fromFirestore(doc))
              .toList(),
        );
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
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .delete();
  }

  Future<void> addContribution(String goalId, double amount) async {
    final goalRef = _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId);
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

  Future<void> updateContribution(
    String goalId,
    String contributionId,
    double amount,
  ) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .collection('contributions')
        .doc(contributionId)
        .update({'amount': amount});
  }

  Stream<List<Map<String, dynamic>>> getContributions(String goalId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .collection('contributions')
        .orderBy('date', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'amount': (data['amount'] ?? 0).toDouble(),
              'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList(),
        );
  }

  // --------------- Course Progress ---------------

  Future<void> saveCourseProgress(
    String courseId,
    int completedLessons,
    int totalLessons,
  ) async {
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

  Future<void> setLessonCompleted(
    String courseId,
    String lessonId,
    bool completed,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('course_progress')
        .doc(courseId)
        .set({
          'completedLessonIds': completed
              ? FieldValue.arrayUnion([lessonId])
              : FieldValue.arrayRemove([lessonId]),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> saveQuizSubmission(
    String courseId,
    String quizId,
    int score,
    int total,
    Map<String, int> answers,
  ) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('quiz_scores')
        .doc('${courseId}_$quizId')
        .set({
          'quizId': quizId,
          'courseId': courseId,
          'score': score,
          'total': total,
          'percentage': total == 0 ? 0 : ((score / total) * 100).round(),
          'answers': answers,
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<Map<String, dynamic>> getQuizScore(String courseId, String quizId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('quiz_scores')
        .doc('${courseId}_$quizId')
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  Future<void> saveQuizScore(
    String courseId,
    String quizId,
    int score,
    int total,
  ) async {
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
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }
}
