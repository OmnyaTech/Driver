class AppVehicle {
  const AppVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.active,
    this.modelYear,
    this.plate,
    this.fuelType,
    this.averageConsumption,
  });

  final String id;
  final String brand;
  final String model;
  final bool active;
  final int? modelYear;
  final String? plate;
  final String? fuelType;
  final double? averageConsumption;
}
