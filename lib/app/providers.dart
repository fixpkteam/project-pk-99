import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/app_storage.dart';
import '../core/storage/device_store.dart';
import '../core/storage/durable_store.dart';
import '../core/storage/read_cache.dart';
import '../core/network/bounded_client.dart';

import 'package:http/http.dart' as http;

import '../features/auth/data/auth_repository.dart';

final configProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
  retry: (count, error) => null,
);
final durableStoreProvider = Provider<DurableStore>((ref) => DeviceStore());
final readCacheProvider = Provider<ReadCache>(
  (ref) => ReadCache(ref.watch(durableStoreProvider)),
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
      httpClient: BoundedClient(http.Client()),
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

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);

final authUserProvider = StreamProvider<User?>((ref) {
  final config = ref.watch(configProvider);
  if (config.preview) return Stream<User?>.value(null);
  return ref.watch(authRepositoryProvider).userChanges;
});

final authEventsProvider = StreamProvider<AuthState>((ref) {
  if (ref.watch(configProvider).preview) return const Stream.empty();
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Read after bootstrap. Supabase has restored its locally persisted session
/// by then; startup does not need to wait for a network or auth-stream event.
final restoredUserProvider = Provider<User?>((ref) {
  if (ref.watch(configProvider).preview) return null;
  return ref.watch(authRepositoryProvider).currentUser;
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

/// Resolve the ordinary launch once, after Supabase restores its local session.
/// Auth events keep updating the app without recreating its navigation stack.
final startupRouteProvider = FutureProvider<String>((ref) async {
  await ref.watch(bootstrapProvider.future);
  final user = ref.read(restoredUserProvider);
  final preferences = ref.read(preferencesProvider);
  if (user != null) {
    // Remember upgraded installations too, so signing out later does not
    // reintroduce an existing customer. This write does not delay Home.
    unawaited(
      preferences
          .setOnboardingCompleted(completed: true)
          .catchError((Object _) {}),
    );
    return '/home';
  }
  final completed = await preferences.getOnboardingCompleted();
  return completed ? '/sign-in' : '/welcome';
}, retry: (count, error) => null);
