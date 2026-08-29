import 'package:intl/intl.dart';

const String kDefaultCurrencyCode = 'UAH';
const String kDefaultCurrencySymbol = '₴';

String formatUah(int amount) {
  final formatted = NumberFormat.decimalPattern('uk_UA').format(amount);
  return '$formatted $kDefaultCurrencySymbol';
}
