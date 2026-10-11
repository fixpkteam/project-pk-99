import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

typedef BackendInitializer = Future<void> Function(AppConfig config);

final backendInitializerProvider = Provider<BackendInitializer>((ref) {
  return (config) async {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: false,
    );
  };
});

/// The initialized Supabase client. Read this only after [bootstrapProvider]
/// has completed successfully.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!Supabase.instance.isInitialized) {
    throw StateError('Supabase is not initialized.');
  }
  return Supabase.instance.client;
});

final bootstrapProvider = FutureProvider<AppConfig>((ref) async {
  final logger = ref.read(loggerProvider);
  logger.record(AppEvent.bootstrapStarted);
  try {
    final config = ref.watch(configProvider);
    config.validate();
    if (!config.preview) {
      await ref.read(backendInitializerProvider)(config);
    }
    logger.record(AppEvent.bootstrapReady);
    return config;
  } on Object {
    logger.record(AppEvent.bootstrapFailed);
    rethrow;
  }
}, retry: (count, error) => null);
