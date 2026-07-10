import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

class AvatarService {
  AvatarService({AuthService? authService, ImagePicker? imagePicker})
    : _authService = authService ?? const AuthService(),
      _imagePicker = imagePicker ?? ImagePicker();

  static const bucketName = 'driver-avatars';

  final AuthService _authService;
  final ImagePicker _imagePicker;

  Future<String?> pickAndUploadProfileAvatar() async {
    final file = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    return _uploadAvatar(bytes: bytes, filename: file.name);
  }

  Future<void> removeProfileAvatar() async {
    final client = _authService.requireClient();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuario nao autenticado.');
    }
    final providerAvatarUrl = user.userMetadata?['avatar_url']?.toString();

    await _deleteExistingAvatars(user.id);
    await client
        .schema('driver')
        .from('profiles')
        .update({
          'avatar_url': providerAvatarUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
  }

  Future<String> _uploadAvatar({
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
        '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$extension';

    await _deleteExistingAvatars(user.id);

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

    final publicUrl = client.storage.from(bucketName).getPublicUrl(path);
    await client
        .schema('driver')
        .from('profiles')
        .update({
          'avatar_url': publicUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', user.id);
    return publicUrl;
  }

  Future<void> _deleteExistingAvatars(String userId) async {
    final client = _authService.requireClient();
    final files = await client.storage.from(bucketName).list(path: userId);
    if (files.isEmpty) return;

    await client.storage
        .from(bucketName)
        .remove(files.map((item) => '$userId/${item.name}').toList());
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
