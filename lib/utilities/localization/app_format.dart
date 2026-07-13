import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../state/app_session.dart';

class AppFormat {
  AppFormat._({required this.localeName, required this.currencyCode});

  final String localeName;
  final String currencyCode;

  static AppFormat of(BuildContext context) {
    final session = context.read<AppSession>();
    final profile = session.profile;
    final locale = Localizations.localeOf(context);
    final localeName =
        profile?.languageCode.replaceAll('-', '_') ??
        locale.toString().replaceAll('-', '_');

    return AppFormat._(
      localeName: localeName,
      currencyCode: profile?.currencyCode ?? 'BRL',
    );
  }

  String currency(num value) {
    return NumberFormat.currency(
      locale: localeName,
      name: currencyCode,
      symbol: _currencySymbol(currencyCode),
      decimalDigits: 2,
    ).format(value);
  }

  String compactCurrency(num value) {
    return NumberFormat.compactCurrency(
      locale: localeName,
      name: currencyCode,
      symbol: _currencySymbol(currencyCode),
      decimalDigits: value.abs() >= 1000 ? 1 : 2,
    ).format(value);
  }

  String number(num value, {int decimalDigits = 0}) {
    return NumberFormat.decimalPatternDigits(
      locale: localeName,
      decimalDigits: decimalDigits,
    ).format(value);
  }

  String date(DateTime value) {
    return DateFormat.yMd(localeName).format(value.toLocal());
  }

  String shortDate(DateTime value) {
    return DateFormat.Md(localeName).format(value.toLocal());
  }

  String dateTime(DateTime value) {
    return DateFormat.yMd(localeName).add_Hm().format(value.toLocal());
  }

  String time(DateTime value) {
    return DateFormat.Hm(localeName).format(value.toLocal());
  }

  String percent(num value, {int decimalDigits = 0}) {
    final pattern = NumberFormat.decimalPercentPattern(
      locale: localeName,
      decimalDigits: decimalDigits,
    );
    return pattern.format(value / 100);
  }

  String _currencySymbol(String code) {
    return switch (code) {
      'USD' => r'US$',
      'EUR' => '\u20ac',
      _ => r'R$',
    };
  }
}
