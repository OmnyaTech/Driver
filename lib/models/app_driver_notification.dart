class AppDriverNotification {
  const AppDriverNotification({
    required this.id,
    required this.notificationKey,
    required this.kind,
    required this.title,
    required this.body,
    required this.actionType,
    required this.actionPayload,
    required this.readAt,
    required this.deliveredAt,
    required this.createdAt,
  });

  final String id;
  final String notificationKey;
  final String kind;
  final String title;
  final String body;
  final String? actionType;
  final Map<String, dynamic> actionPayload;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;
}
