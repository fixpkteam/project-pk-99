import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/app_storage.dart';

final configProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
  retry: (count, error) => null,
);
final loggerProvider = Provider<AppLogger>((ref) => const AppLogger());
final preferencesProvider = Provider<PreferencesStore>(
  (ref) => LocalPreferencesStore(SharedPreferencesAsync()),
);
final secretStoreProvider = Provider<SecretStore>(
  (ref) => const DeviceSecretStore(FlutterSecureStorage()),
);

final bootstrapProvider = FutureProvider<AppConfig>((ref) async {
  final logger = ref.read(loggerProvider);
  logger.record(AppEvent.bootstrapStarted);
  try {
    final config = ref.watch(configProvider);
    config.validate();
    if (!config.preview) {
      throw const ConfigurationException(
        'Connected services will be enabled in the next development phase.',
      );
    }
    logger.record(AppEvent.bootstrapReady);
    return config;
  } on Object {
    logger.record(AppEvent.bootstrapFailed);
    rethrow;
  }
}, retry: (count, error) => null);
