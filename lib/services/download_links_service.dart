import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class DriverDownloadLinks {
  const DriverDownloadLinks({
    required this.officialApkUrl,
    required this.mediafireApkUrl,
  });

  final String officialApkUrl;
  final String? mediafireApkUrl;
}

class DownloadLinksService {
  const DownloadLinksService();

  static const _fallbackMediafireUrl =
      'https://www.mediafire.com/file/cehfkctgxvhcqlu/driver-v1.0.17.apk/file';

  Future<DriverDownloadLinks> fetchLinks() async {
    final fallback = const DriverDownloadLinks(
      officialApkUrl: SupabaseRuntimeConfig.driverApkUrl,
      mediafireApkUrl: _fallbackMediafireUrl,
    );

    if (!SupabaseRuntimeConfig.isConfigured) return fallback;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'driver-download-links',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return fallback;

      final official = _readUrl(data['official_apk_url']);
      final mediafire = _readUrl(data['mediafire_apk_url']);

      return DriverDownloadLinks(
        officialApkUrl: official ?? fallback.officialApkUrl,
        mediafireApkUrl: mediafire ?? fallback.mediafireApkUrl,
      );
    } catch (_) {
      return fallback;
    }
  }

  String? _readUrl(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return null;
    return trimmed;
  }
}
