class AppFueling {
  const AppFueling({
    required this.id,
    required this.fueledAt,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.journeyId,
    required this.stationName,
    required this.fuelType,
    required this.odometer,
    required this.liters,
    required this.pricePerLiter,
    required this.totalAmount,
  });

  final String id;
  final DateTime fueledAt;
  final String vehicleId;
  final String? vehicleLabel;
  final String? journeyId;
  final String? stationName;
  final String? fuelType;
  final double? odometer;
  final double liters;
  final double pricePerLiter;
  final double totalAmount;
}
