import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ bảo mật JWT Access Token trên cả Mobile (Keychain/Keystore) và Web (WebCrypto).
class SecureTokenStorage {
  static const String _accessTokenKey = 'familyfund_access_token';
  static const String _activeClanIdKey = 'familyfund_active_clan_id';

  final FlutterSecureStorage _storage;
  final void Function()? onSessionChanged;

  const SecureTokenStorage(this._storage, {this.onSessionChanged});

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    onSessionChanged?.call();
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> saveActiveClanId(String clanId) async {
    await _storage.write(key: _activeClanIdKey, value: clanId);
    onSessionChanged?.call();
  }

  Future<String?> getActiveClanId() async {
    return _storage.read(key: _activeClanIdKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    onSessionChanged?.call();
  }
}

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  const storage = FlutterSecureStorage();
  return SecureTokenStorage(
    storage,
    onSessionChanged: () {
      ref.read(privateSessionRevisionProvider.notifier).advance();
    },
  );
});

/// Invalidates private content when credentials or the active clan change.
class PrivateSessionRevision extends Notifier<int> {
  @override
  int build() => 0;
  void advance() => state++;
}

final privateSessionRevisionProvider =
    NotifierProvider<PrivateSessionRevision, int>(PrivateSessionRevision.new);
