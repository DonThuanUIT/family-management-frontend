import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ bảo mật JWT Access Token trên cả Mobile (Keychain/Keystore) và Web (WebCrypto).
class SecureTokenStorage {
  static const String _accessTokenKey = 'familyfund_access_token';
  static const String _activeClanIdKey = 'familyfund_active_clan_id';

  final FlutterSecureStorage _storage;

  const SecureTokenStorage(this._storage);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveActiveClanId(String clanId) async {
    await _storage.write(key: _activeClanIdKey, value: clanId);
  }

  Future<String?> getActiveClanId() async {
    return _storage.read(key: _activeClanIdKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  const storage = FlutterSecureStorage();
  return const SecureTokenStorage(storage);
});
