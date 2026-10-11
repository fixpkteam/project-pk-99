import 'dart:developer' as developer;

enum AppEvent {
  bootstrapStarted,
  bootstrapReady,
  bootstrapFailed,
  unexpectedFailure,
}

/// Deliberately accepts no free-text context, payload, URL, token or exception.
class AppLogger {
  const AppLogger();
  void record(AppEvent event) {
    developer.log(event.name, name: 'fixpk');
  }
}
