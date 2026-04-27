import 'package:flutter_test/flutter_test.dart';

import 'package:finease/data/demo_finance_data.dart';

void main() {
  test('demo courses include lessons and quizzes', () {
    expect(DemoFinanceData.courses, isNotEmpty);
    for (final course in DemoFinanceData.courses) {
      expect(course.lessons, isNotEmpty);
      expect(course.quiz.questions, isNotEmpty);
    }
  });

  test('demo savings and transactions are seeded', () {
    expect(DemoFinanceData.sampleGoals(), isNotEmpty);
    expect(DemoFinanceData.sampleTransactions(), isNotEmpty);
  });
}
