class AppTripExpense {
  const AppTripExpense({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.occurredAt,
    required this.journeyId,
    required this.journeyLabel,
  });

  final String id;
  final String type;
  final String? description;
  final double amount;
  final DateTime occurredAt;
  final String? journeyId;
  final String? journeyLabel;
}
