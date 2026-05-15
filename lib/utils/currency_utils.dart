import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _standardFormatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  static String format(double value, {bool compact = false}) {
    return _standardFormatter.format(value);
  }

  static String number(num value) {
    return NumberFormat.decimalPattern('en_PK').format(value);
  }

  static String exact(num value) {
    if (!value.isFinite) {
      return '0';
    }
    final normalized = value.abs() < 0.000001 ? 0 : value;
    if (normalized % 1 == 0) {
      return normalized.toStringAsFixed(0);
    }
    return normalized.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
