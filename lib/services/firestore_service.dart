import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/saving_goal.dart';
import '../models/transaction.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String uid;

  FirestoreService({required this.uid});

  // --- Transactions ---
  Stream<List<FinancialTransaction>> getTransactions() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc))
            .toList());
  }

  Future<void> addTransaction(FinancialTransaction transaction) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .add(transaction.toMap());
  }

  // --- Saving Goals ---
  Stream<List<SavingGoal>> getSavingGoals() {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavingGoal.fromFirestore(doc)).toList());
  }

  Future<void> addSavingGoal(SavingGoal goal) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .add(goal.toMap());
  }

  Future<void> updateSavingGoalAmount(String goalId, double newAmount) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('saving_goals')
        .doc(goalId)
        .update({'currentAmount': newAmount});
  }
}
