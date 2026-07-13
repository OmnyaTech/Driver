enum DriverReserveMode { none, dailyPercent, perDeliveryFixed }

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
      DriverReserveMode.dailyPercent =>
        '${dailyPercentage.toStringAsFixed(dailyPercentage.truncateToDouble() == dailyPercentage ? 0 : 1)}% do que sobrar',
      DriverReserveMode.perDeliveryFixed => 'Valor por entrega concluida',
    };
  }

  String summaryLabelWith(String Function(double value) currency) {
    return switch (mode) {
      DriverReserveMode.none => 'Reserva automatica desativada',
      DriverReserveMode.dailyPercent =>
        '${dailyPercentage.toStringAsFixed(dailyPercentage.truncateToDouble() == dailyPercentage ? 0 : 1)}% do que sobrar',
      DriverReserveMode.perDeliveryFixed =>
        '${currency(amountPerDelivery)} por entrega concluida',
    };
  }
}
