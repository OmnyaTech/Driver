import '../../models/user_role.dart';
import '../../services/developer_access_service.dart';

class DeveloperGuard {
  DeveloperGuard({DeveloperAccessService? accessService})
    : _accessService = accessService ?? const DeveloperAccessService();

  final DeveloperAccessService _accessService;

  bool canOpen(UserRole role) => _accessService.canAccessDeveloperArea(role);
}
