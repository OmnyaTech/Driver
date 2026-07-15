import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class DriverDownloadLinks {
  const DriverDownloadLinks({required this.mediafireApkUrl});

  final String mediafireApkUrl;
}

class DownloadLinksService {
  const DownloadLinksService();

  static const _fallbackMediafireUrl =
      'https://www.mediafire.com/file/cehfkctgxvhcqlu/driver-v1.0.17.apk/file';

  Future<DriverDownloadLinks> fetchLinks() async {
    final fallback = const DriverDownloadLinks(
      mediafireApkUrl: _fallbackMediafireUrl,
    );

    if (!SupabaseRuntimeConfig.isConfigured) return fallback;

    try {
      final response = await Supabase.instance.client.functions.invoke(
        'driver-download-links',
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return fallback;

      final mediafire = _readUrl(data['mediafire_apk_url']);

      return DriverDownloadLinks(
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
