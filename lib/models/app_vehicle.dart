class AppVehicle {
  const AppVehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.active,
    this.type,
    this.modelYear,
    this.plate,
    this.fuelType,
    this.fuelTypes = const [],
    this.averageConsumption,
  });

  final String id;
  final String brand;
  final String model;
  final bool active;
  final String? type;
  final int? modelYear;
  final String? plate;
  final String? fuelType;
  final List<String> fuelTypes;
  final double? averageConsumption;

  List<String> get effectiveFuelTypes {
    if (fuelTypes.isNotEmpty) return fuelTypes;
    final legacy = fuelType?.trim();
    return legacy == null || legacy.isEmpty ? const [] : [legacy];
  }
}
