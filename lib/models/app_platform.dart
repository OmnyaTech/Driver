class AppPlatform {
  const AppPlatform({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    this.averageIncome,
    this.averageDeliveries,
  });

  final String id;
  final String name;
  final String type;
  final bool active;
  final double? averageIncome;
  final int? averageDeliveries;
}
