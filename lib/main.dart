import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/fixpk_app.dart';
import 'core/logging/app_logger.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  const logger = AppLogger();
  FlutterError.onError = (details) {
    // Do not forward exception payloads: they may contain private data.
    logger.record(AppEvent.unexpectedFailure);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.record(AppEvent.unexpectedFailure);
    return true;
  };
  runApp(const ProviderScope(child: FixPkApp()));
}
