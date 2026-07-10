class AppGoal {
  const AppGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.deadline,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? icon;
  final DateTime? deadline;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress {
    if (targetAmount <= 0) return 0;
    final ratio = currentAmount / targetAmount;
    if (ratio < 0) return 0;
    if (ratio > 1) return 1;
    return ratio;
  }

  double get remainingAmount {
    final remaining = targetAmount - currentAmount;
    return remaining < 0 ? 0 : remaining;
  }
}

class AppGoalTransaction {
  const AppGoalTransaction({
    required this.id,
    required this.goalId,
    required this.goalTitle,
    required this.amount,
    required this.createdAt,
    required this.journeyId,
    required this.journeyLabel,
  });

  final String id;
  final String goalId;
  final String goalTitle;
  final double amount;
  final DateTime createdAt;
  final String? journeyId;
  final String? journeyLabel;

  bool get isContribution => amount >= 0;
}

class GoalBalanceSummary {
  const GoalBalanceSummary({
    required this.netOperationalResult,
    required this.allocatedToGoals,
    required this.availableBalance,
  });

  final double netOperationalResult;
  final double allocatedToGoals;
  final double availableBalance;
}
