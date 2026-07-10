import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class PlatformLogoService {
  PlatformLogoService({AuthService? authService, ImagePicker? imagePicker})
    : _authService = authService ?? const AuthService(),
      _imagePicker = imagePicker ?? ImagePicker();

  static const bucketName = 'driver-platform-logos';

  final AuthService _authService;
  final ImagePicker _imagePicker;

  Future<String?> pickAndUploadLogo({required String platformId}) async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return _uploadLogo(
      platformId: platformId,
      bytes: bytes,
      filename: file.name,
    );
  }

  Future<void> removeLogo({required String platformId}) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    await _deletePlatformFiles(user.id, platformId);
  }

  Future<String> _uploadLogo({
    required String platformId,
    required Uint8List bytes,
    required String filename,
  }) async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }

    final extension = _extensionFromFilename(filename);
    final path =
        '${user.id}/$platformId/logo_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _deletePlatformFiles(user.id, platformId);

    await client.storage
        .from(bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFromExtension(extension),
          ),
        );

    return client.storage.from(bucketName).getPublicUrl(path);
  }

  Future<void> _deletePlatformFiles(String userId, String platformId) async {
    final client = _authService.requireClient();
    final path = '$userId/$platformId';
    final files = await client.storage.from(bucketName).list(path: path);
    if (files.isEmpty) return;

    await client.storage
        .from(bucketName)
        .remove(files.map((item) => '$path/${item.name}').toList());
  }

  String _extensionFromFilename(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'png';
    if (lower.endsWith('.webp')) return 'webp';
    return 'jpg';
  }

  String _contentTypeFromExtension(String extension) {
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
