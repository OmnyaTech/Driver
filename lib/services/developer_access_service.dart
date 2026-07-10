import '../models/user_role.dart';

class DeveloperAccessService {
  const DeveloperAccessService();

  bool canAccessDeveloperArea(UserRole role) {
    return role == UserRole.developer;
  }
}
