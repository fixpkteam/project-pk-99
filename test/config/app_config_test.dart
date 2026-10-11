import 'package:fixpk/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('development preview runs without backend credentials', () {
    final config = AppConfig.fromValues({});
    expect(config.preview, isTrue);
    expect(config.environment, AppEnvironment.development);
  });
  test('unknown environments and invalid booleans fail closed', () {
    expect(
      () => AppConfig.fromValues({'APP_ENV': 'prodution'}),
      throwsA(isA<ConfigurationException>()),
    );
    expect(
      () => AppConfig.fromValues({'FOUNDATION_PREVIEW': 'yes'}),
      throwsA(isA<ConfigurationException>()),
    );
  });
  test('staging and production cannot run preview', () {
    for (final env in ['staging', 'production']) {
      expect(
        () => AppConfig.fromValues({'APP_ENV': env}),
        throwsA(isA<ConfigurationException>()),
      );
    }
  });
  test('connected mode rejects missing or unsafe backend configuration', () {
    for (final url in [
      '',
      'http://example.com',
      'https://user:pass@example.com',
      'https://example.com/path',
    ]) {
      expect(
        () => AppConfig.fromValues({
          'FOUNDATION_PREVIEW': 'false',
          'SUPABASE_URL': url,
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        }),
        throwsA(isA<ConfigurationException>()),
      );
    }
    expect(
      () => AppConfig.fromValues({
        'FOUNDATION_PREVIEW': 'false',
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_test',
      }),
      throwsA(isA<ConfigurationException>()),
    );
  });
  test('valid public configuration passes validation', () {
    final config = AppConfig.fromValues({
      'APP_ENV': 'staging',
      'FOUNDATION_PREVIEW': 'false',
      'SUPABASE_URL': 'https://example.supabase.co',
      'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    });
    expect(config.environment, AppEnvironment.staging);
  });
}
