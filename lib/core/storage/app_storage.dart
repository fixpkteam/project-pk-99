import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class PreferencesStore {
  Future<bool> getOnboardingCompleted();
  Future<void> setOnboardingCompleted({required bool completed});
}

class LocalPreferencesStore implements PreferencesStore {
  LocalPreferencesStore(this._preferences);
  final SharedPreferencesAsync _preferences;
  static const _onboardingKey = 'fixpk.onboarding.completed.v1';

  @override
  Future<bool> getOnboardingCompleted() async =>
      await _preferences.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingCompleted({required bool completed}) =>
      _preferences.setBool(_onboardingKey, completed);
}

abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Adapter only in Phase 1. Authentication/session persistence is Phase 2.
class DeviceSecretStore implements SecretStore {
  const DeviceSecretStore(this._storage);
  final FlutterSecureStorage _storage;
  String _key(String key) => 'fixpk.$key';

  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));
}
