import 'package:intl/intl.dart';

import 'constants.dart';

/// Formatage centralisé : montants, pointures, dates.
class Fmt {
  Fmt._();

  static final NumberFormat _money = NumberFormat.currency(
    locale: kLocale,
    symbol: kCurrencySymbol,
    decimalDigits: 2,
  );

  static final NumberFormat _moneyCompact = NumberFormat.compactCurrency(
    locale: kLocale,
    symbol: kCurrencySymbol,
    decimalDigits: 1,
  );

  static final NumberFormat _int = NumberFormat.decimalPattern(kLocale);

  /// 1234.5 -> "1 234,50 €"
  static String money(num value) => _money.format(value);

  /// Version courte pour les grands montants : "12,3 k€"
  static String moneyShort(num value) =>
      value.abs() >= 10000 ? _moneyCompact.format(value) : _money.format(value);

  static String number(num value) => _int.format(value);

  /// 42.0 -> "42" ; 42.5 -> "42,5"
  static String size(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  /// 34.5 -> "+34,5 %"
  static String percent(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  static String date(DateTime value) =>
      DateFormat('d MMMM y', kLocale).format(value);

  /// Convertit une saisie utilisateur ("12,90") en double.
  static double? parseNumber(String? input) {
    if (input == null) return null;
    final cleaned = input.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
