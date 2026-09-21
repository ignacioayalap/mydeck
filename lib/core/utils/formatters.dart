import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _eurFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );

  /// Format USD price
  static String formatUsd(double? price) {
    if (price == null || price <= 0) return '\$0.00';
    return _currencyFormat.format(price);
  }

  /// Format EUR price
  static String formatEur(double? price) {
    if (price == null || price <= 0) return '€0.00';
    return _eurFormat.format(price);
  }

  /// Safe parse string price from Scryfall API
  static double parsePrice(dynamic priceValue) {
    if (priceValue == null) return 0.0;
    if (priceValue is num) return priceValue.toDouble();
    if (priceValue is String) {
      return double.tryParse(priceValue) ?? 0.0;
    }
    return 0.0;
  }

  /// Format Date
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }
}
