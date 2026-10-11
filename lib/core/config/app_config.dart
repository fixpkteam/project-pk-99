enum AppEnvironment { development, staging, production }

/// Build-time public configuration. No server secret belongs in a mobile app.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.preview,
    this.supabaseUrl = '',
    this.supabasePublishableKey = '',
  });

  factory AppConfig.fromValues(Map<String, String> values) {
    final name = values['APP_ENV'] ?? 'development';
    final environment = AppEnvironment.values.where(
      (item) => item.name == name,
    );
    if (environment.isEmpty) {
      throw const ConfigurationException(
        'Choose a valid application environment.',
      );
    }
    final previewValue = values['FOUNDATION_PREVIEW'] ?? 'true';
    if (previewValue != 'true' && previewValue != 'false') {
      throw const ConfigurationException('Preview mode must be true or false.');
    }
    final config = AppConfig(
      environment: environment.single,
      preview: previewValue == 'true',
      supabaseUrl: values['SUPABASE_URL'] ?? '',
      supabasePublishableKey: values['SUPABASE_PUBLISHABLE_KEY'] ?? '',
    );
    config.validate();
    return config;
  }

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(const {
    'APP_ENV': String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    'FOUNDATION_PREVIEW': String.fromEnvironment(
      'FOUNDATION_PREVIEW',
      defaultValue: 'true',
    ),
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_PUBLISHABLE_KEY': String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
  });

  final AppEnvironment environment;
  final bool preview;
  final String supabaseUrl;
  final String supabasePublishableKey;

  void validate() {
    if (environment != AppEnvironment.development && preview) {
      throw const ConfigurationException(
        'Preview builds are limited to development.',
      );
    }
    if (preview) return;
    final uri = Uri.tryParse(supabaseUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const ConfigurationException(
        'A valid HTTPS backend origin is required.',
      );
    }
    // Accept only the explicit public-key format. Never accept server secrets
    // or opaque legacy JWTs whose role cannot be verified here.
    if (!supabasePublishableKey.startsWith('sb_publishable_') ||
        supabasePublishableKey.length <= 'sb_publishable_'.length) {
      throw const ConfigurationException(
        'A public backend publishable key is required.',
      );
    }
  }
}

class ConfigurationException implements Exception {
  const ConfigurationException(this.message);
  final String message;
  @override
  String toString() => message;
}
