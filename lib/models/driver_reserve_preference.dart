enum DriverReserveMode {
  none,
  perDeliveryPercent,
  perDeliveryFixed,
  dailyPercent,
  weeklyPercent,
  monthlyPercent,
}

class DriverReservePreference {
  const DriverReservePreference({
    required this.mode,
    required this.dailyPercentage,
    required this.amountPerDelivery,
  });

  final DriverReserveMode mode;
  final double dailyPercentage;
  final double amountPerDelivery;

  String get summaryLabel {
    return switch (mode) {
      DriverReserveMode.none => 'Reserva automatica desativada',
      DriverReserveMode.perDeliveryPercent =>
        '${_percentageLabel(dailyPercentage)}% por entrega',
      DriverReserveMode.perDeliveryFixed => 'Valor por entrega concluida',
      DriverReserveMode.dailyPercent =>
        '${_percentageLabel(dailyPercentage)}% por dia',
      DriverReserveMode.weeklyPercent =>
        '${_percentageLabel(dailyPercentage)}% por semana',
      DriverReserveMode.monthlyPercent =>
        '${_percentageLabel(dailyPercentage)}% por mes',
    };
  }

  String summaryLabelWith(String Function(double value) currency) {
    return switch (mode) {
      DriverReserveMode.none => 'Reserva automatica desativada',
      DriverReserveMode.perDeliveryPercent =>
        '${_percentageLabel(dailyPercentage)}% por entrega',
      DriverReserveMode.perDeliveryFixed =>
        '${currency(amountPerDelivery)} por entrega concluida',
      DriverReserveMode.dailyPercent =>
        '${_percentageLabel(dailyPercentage)}% por dia',
      DriverReserveMode.weeklyPercent =>
        '${_percentageLabel(dailyPercentage)}% por semana',
      DriverReserveMode.monthlyPercent =>
        '${_percentageLabel(dailyPercentage)}% por mes',
    };
  }

  String _percentageLabel(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}
