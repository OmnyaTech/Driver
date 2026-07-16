import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_version_gate_result.dart';
import 'auth_service.dart';

class AppVersionGateService {
  AppVersionGateService({AuthService? authService})
    : _authService = authService ?? const AuthService();

  final AuthService _authService;

  Future<AppVersionGateResult> check() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(packageInfo.buildNumber) ?? 1;
    final installedVersion = packageInfo.version;
    final platform = _platformName();

    try {
      final client = _authService.client;
      if (client == null) {
        return _allow(
          installedVersion: installedVersion,
          installedBuild: installedBuild,
        );
      }

      final rows = await client
          .schema('driver')
          .from('app_version_rules')
          .select()
          .eq('platform', platform)
          .eq('enabled', true)
          .limit(1);

      final row = rows.isNotEmpty
          ? Map<String, dynamic>.from(rows.first as Map)
          : null;
      if (row == null) {
        return _allow(
          installedVersion: installedVersion,
          installedBuild: installedBuild,
        );
      }

      final minimumBuild = _asInt(row['minimum_build_number'], fallback: 1);
      final latestBuild = _asInt(
        row['latest_build_number'],
        fallback: minimumBuild,
      );
      final latestVersion = (row['latest_version'] ?? installedVersion)
          .toString();
      final graceDays = _asInt(row['grace_period_days'], fallback: 7);
      final startedAt = DateTime.tryParse(
        (row['enforcement_started_at'] ?? '').toString(),
      );
      final elapsed = startedAt == null
          ? 0
          : DateTime.now().toUtc().difference(startedAt.toUtc()).inDays;
      final daysRemaining = (graceDays - elapsed).clamp(0, graceDays);
      final belowMinimum = installedBuild < minimumBuild;
      final updateAvailable = installedBuild < latestBuild || belowMinimum;
      final updateUrl = await _resolveUpdateUrl(row['update_url']?.toString());

      return AppVersionGateResult(
        installedVersion: installedVersion,
        installedBuildNumber: installedBuild,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuild,
        minimumBuildNumber: minimumBuild,
        updateUrl: updateUrl,
        daysRemaining: daysRemaining,
        updateAvailable: updateAvailable,
        blocked: belowMinimum || (updateAvailable && daysRemaining == 0),
      );
    } catch (_) {
      return _allow(
        installedVersion: installedVersion,
        installedBuild: installedBuild,
      );
    }
  }

  AppVersionGateResult _allow({
    required String installedVersion,
    required int installedBuild,
  }) {
    return AppVersionGateResult(
      installedVersion: installedVersion,
      installedBuildNumber: installedBuild,
      latestVersion: installedVersion,
      latestBuildNumber: installedBuild,
      minimumBuildNumber: installedBuild,
      updateUrl: null,
      daysRemaining: 7,
      updateAvailable: false,
      blocked: false,
    );
  }

  int _asInt(Object? value, {required int fallback}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<String?> _resolveUpdateUrl(String? configuredUrl) async {
    final trimmedUrl = configuredUrl?.trim();
    if (_isHttpUrl(trimmedUrl)) return trimmedUrl;

    try {
      final client = _authService.client;
      if (client == null) return null;

      final response = await client.functions.invoke('driver-download-links');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final mediafireUrl = data['mediafire_apk_url']?.toString().trim();
        if (_isHttpUrl(mediafireUrl)) return mediafireUrl;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _isHttpUrl(String? value) {
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'android',
    };
  }
}
