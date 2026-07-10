class AppPlatform {
  const AppPlatform({
    required this.id,
    required this.name,
    required this.type,
    required this.active,
    this.logoUrl,
    this.averageIncome,
    this.averageDeliveries,
  });

  final String id;
  final String name;
  final String type;
  final bool active;
  final String? logoUrl;
  final double? averageIncome;
  final int? averageDeliveries;
}
