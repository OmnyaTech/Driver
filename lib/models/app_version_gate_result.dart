class AppVersionGateResult {
  const AppVersionGateResult({
    required this.installedVersion,
    required this.installedBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.minimumBuildNumber,
    required this.updateUrl,
    required this.daysRemaining,
    required this.updateAvailable,
    required this.blocked,
  });

  final String installedVersion;
  final int installedBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
  final int minimumBuildNumber;
  final String? updateUrl;
  final int daysRemaining;
  final bool updateAvailable;
  final bool blocked;

  bool get canContinue => !blocked;
}
