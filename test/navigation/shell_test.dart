import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/fixpk_app.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/config/app_config.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('tabs preserve service search and navigate without a backend', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FixPkApp()));
    await tester.pumpAndSettle();
    expect(find.text('Engineering Solutions.\nBuilt to Last.'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'CCTV');
    await tester.pumpAndSettle();
    expect(find.text('CCTV & Security'), findsOneWidget);
    expect(find.text('Solar Solutions'), findsNothing);
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to FixPK'), findsOneWidget);
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(find.text('CCTV'), findsOneWidget);
    expect(find.text('Solar Solutions'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unknown deep link returns safely to home', (tester) async {
    final router = createRouter(initialLocation: '/unavailable/123');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(theme: FixPkTheme.light, routerConfig: router),
    );
    await tester.pumpAndSettle();
    expect(find.text('This page is unavailable'), findsOneWidget);
    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();
    expect(find.text('Engineering Solutions.\nBuilt to Last.'), findsOneWidget);
  });
  testWidgets('startup error is recoverable and does not expose credentials', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWith((ref) {
            attempts++;
            if (attempts == 1) {
              throw StateError('private-token-must-not-appear');
            }
            return const AppConfig(
              environment: AppEnvironment.development,
              preview: true,
            );
          }),
        ],
        child: const FixPkApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FixPK could not start'), findsOneWidget);
    expect(find.textContaining('private-token'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
    expect(attempts, greaterThan(0));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Engineering Solutions.\nBuilt to Last.'), findsOneWidget);
  });
  testWidgets('connected mode initializes Supabase before showing the app', (
    tester,
  ) async {
    var initializedUrl = '';
    var initializedKey = '';
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.staging,
              preview: false,
              supabaseUrl: 'https://example.supabase.co',
              supabasePublishableKey: 'sb_publishable_test',
            ),
          ),
          backendInitializerProvider.overrideWithValue((config) async {
            initializedUrl = config.supabaseUrl;
            initializedKey = config.supabasePublishableKey;
          }),
        ],
        child: const FixPkApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Engineering Solutions.\nBuilt to Last.'), findsOneWidget);
    expect(initializedUrl, 'https://example.supabase.co');
    expect(initializedKey, 'sb_publishable_test');
  });
}
