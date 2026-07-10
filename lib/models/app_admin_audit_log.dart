class AppAdminAuditLog {
  const AppAdminAuditLog({
    required this.id,
    required this.action,
    required this.summary,
    required this.actorEmail,
    required this.targetEmail,
    required this.createdAt,
    required this.metadata,
  });

  final String id;
  final String action;
  final String? summary;
  final String? actorEmail;
  final String? targetEmail;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
}
