class AppMaintenance {
  const AppMaintenance({
    required this.id,
    required this.maintenanceDate,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.workshop,
    required this.reason,
    required this.description,
    required this.totalAmount,
    required this.items,
  });

  final String id;
  final DateTime maintenanceDate;
  final String vehicleId;
  final String? vehicleLabel;
  final String? workshop;
  final String? reason;
  final String? description;
  final double totalAmount;
  final List<AppMaintenanceItem> items;
}

class AppMaintenanceItem {
  const AppMaintenanceItem({required this.description, required this.amount});

  final String description;
  final double amount;
}
