import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedLoginCredentials {
  const SavedLoginCredentials({required this.email, required this.password});

  final String email;
  final String password;

  bool get isNotEmpty => email.trim().isNotEmpty && password.isNotEmpty;
}

class SavedLoginService {
  SavedLoginService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _emailKey = 'driver_saved_login_email';
  static const _passwordKey = 'driver_saved_login_password';

  final FlutterSecureStorage _storage;

  Future<SavedLoginCredentials?> load() async {
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    if (email == null ||
        email.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return SavedLoginCredentials(email: email, password: password);
  }

  Future<void> save({required String email, required String password}) async {
    await _storage.write(key: _emailKey, value: email.trim());
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }
}
