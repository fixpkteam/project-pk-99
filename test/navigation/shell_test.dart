import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/fixpk_app.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/config/app_config.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:fixpk/features/care/data/care_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('tabs preserve service search and navigate without a backend', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FixPkApp()));
    await tester.pumpAndSettle();
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
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
      ProviderScope(
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('This page is unavailable'), findsOneWidget);
    await tester.tap(find.text('Go home'));
    await tester.pumpAndSettle();
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
  });

  testWidgets('product and project routes have useful preview states', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FixPkApp()));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Products'));
    await tester.tap(find.text('Products'));
    await tester.pumpAndSettle();
    expect(find.text('Products & solutions'), findsOneWidget);
    expect(find.text('Solar Water Heater'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(3));
    await tester.pumpAndSettle();
    expect(find.text('Selected projects'), findsOneWidget);
    expect(find.text('Rooftop Solar Installation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin routes deny guests until a staff admin role is verified', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/admin');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin sign-in required'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin routes deny a signed-in customer without the admin role', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/admin');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(_testUser)),
          staffRoleListProvider.overrideWith(
            (ref, userId) async => [
              const StaffRoleRecord(userId: 'customer-1', role: 'support'),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Admin access required'), findsOneWidget);
    expect(find.text('FixPK control center'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified admins can open the content management panel', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/admin');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(_testUser)),
          staffRoleListProvider.overrideWith(
            (ref, userId) async => [
              const StaffRoleRecord(userId: 'admin-1', role: 'admin'),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('FixPK control center'), findsOneWidget);
    expect(find.text('Users and staff access'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
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
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
    expect(initializedUrl, 'https://example.supabase.co');
    expect(initializedKey, 'sb_publishable_test');
  });

  testWidgets('guest can reach account creation and sees preview guidance', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FixPkApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Join FixPK'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Aamir Hassan');
    await tester.enterText(find.byType(TextFormField).at(1), '+923001234567');
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'aamir@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(3), 'safe-pass-123');
    await tester.drag(find.byType(ListView).last, const Offset(0, -280));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Connect the Supabase environment to use customer accounts.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

final _testUser = User(
  id: 'admin-1',
  appMetadata: const {},
  userMetadata: const {'full_name': 'Test Admin'},
  aud: 'authenticated',
  createdAt: '2026-10-11T12:00:00Z',
  email: 'admin@example.test',
);
