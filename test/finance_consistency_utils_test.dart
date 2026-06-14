import 'package:finease/utils/finance_consistency_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FinanceConsistencyUtils', () {
    test('uses transaction income instead of adding profile income again', () {
      final income = FinanceConsistencyUtils.resolvePeriodIncome(
        profileMonthlyIncome: 50000,
        transactionIncome: 50000,
        periodType: 'monthly',
      );

      expect(income, 50000);
    });

    test(
      'falls back to scaled profile income when no income transaction exists',
      () {
        final income = FinanceConsistencyUtils.resolvePeriodIncome(
          profileMonthlyIncome: 60000,
          transactionIncome: 0,
          periodType: 'weekly',
        );

        expect(income, closeTo(13808.98, 0.01));
      },
    );

    test('prefers monthly summary for transaction previews', () {
      final income = FinanceConsistencyUtils.resolveMonthlyIncome(
        profileMonthlyIncome: 50000,
        transactionIncome: 50000,
        summaryIncome: 75000,
      );

      expect(income, 75000);
    });
  });
}
