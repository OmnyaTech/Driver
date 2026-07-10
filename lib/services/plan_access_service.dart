import '../models/plan_type.dart';

class PlanAccessService {
  const PlanAccessService();

  bool canUseMultipleVehicles(PlanType planType) {
    return _hasExpandedAccess(planType);
  }

  bool canUseMultiplePlatforms(PlanType planType) {
    return _hasExpandedAccess(planType);
  }

  bool canAccessAdvancedOperations(PlanType planType) {
    return _hasExpandedAccess(planType);
  }

  bool _hasExpandedAccess(PlanType planType) {
    return switch (planType) {
      PlanType.free => false,
      PlanType.premium ||
      PlanType.gift ||
      PlanType.lifetime ||
      PlanType.developer => true,
    };
  }
}
