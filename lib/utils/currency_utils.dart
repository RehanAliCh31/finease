import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 1,
  );

  static final NumberFormat _standardFormatter = NumberFormat.currency(
    locale: 'en_PK',
    symbol: 'PKR ',
    decimalDigits: 0,
  );

  static String format(double value, {bool compact = false}) {
    return compact
        ? _compactFormatter.format(value)
        : _standardFormatter.format(value);
  }
}
