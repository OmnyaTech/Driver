final class PushMessagingTokenBundle {
  const PushMessagingTokenBundle({
    this.fcmToken,
    this.apnsToken,
    this.permissionDenied = false,
  });

  final String? fcmToken;
  final String? apnsToken;
  final bool permissionDenied;
}

final class PushMessagingAdapter {
  const PushMessagingAdapter();

  Future<bool> initialize() async => false;

  Future<PushMessagingTokenBundle?> requestTokenBundle() async => null;
}
