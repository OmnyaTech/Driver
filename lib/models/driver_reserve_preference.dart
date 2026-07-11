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
      DriverReserveMode.perDeliveryFixed =>
        'R\$ ${amountPerDelivery.toStringAsFixed(2)} por entrega concluida',
    };
  }
}
