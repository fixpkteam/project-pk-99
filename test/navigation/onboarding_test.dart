import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/fixpk_app.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/memory_preferences.dart';

final _user = User(
  id: 'returning-customer',
  appMetadata: {},
  userMetadata: {'full_name': 'Test customer'},
  aud: 'authenticated',
  createdAt: '2026-10-13T00:00:00Z',
);

Future<void> _launch(
  WidgetTester tester,
  MemoryPreferences preferences, {
  User? user,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        restoredUserProvider.overrideWithValue(user),
        authUserProvider.overrideWith((ref) => Stream.value(user)),
      ],
      child: const FixPkApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-next')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch introduces the app then persists completion', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    await _launch(tester, preferences);
    expect(find.text('Welcome to FixPK'), findsOneWidget);
    expect(preferences.completed, isFalse);
    await _next(tester);
    expect(find.text('One app. Every solution.'), findsOneWidget);
    await _next(tester);
    expect(find.text('Let’s get your project started.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    await _next(tester);
    expect(find.text('Join FixPK'), findsOneWidget);
    expect(preferences.completed, isTrue);
    expect(preferences.writes, 1);

    // A new app container uses the persisted flag and resumes authentication.
    await _launch(tester, preferences);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Welcome to FixPK'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning signed-in users open Home even without a local flag', (
    tester,
  ) async {
    final preferences = MemoryPreferences()..failReads = true;
    await _launch(tester, preferences, user: _user);
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(preferences.completed, isTrue);
    preferences.failReads = false;
    await _launch(tester, preferences);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Welcome to FixPK'), findsNothing);
  });

  testWidgets('incomplete introduction repeats; previous-page action works', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    await _launch(tester, preferences);
    await _next(tester);
    await tester.tap(find.byTooltip('Previous introduction'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to FixPK'), findsOneWidget);
    await _next(tester);
    await _launch(tester, preferences);
    expect(find.text('Welcome to FixPK'), findsOneWidget);
    expect(preferences.completed, isFalse);
  });

  testWidgets('preference read failure offers a working retry', (tester) async {
    final preferences = MemoryPreferences()..failReads = true;
    await _launch(tester, preferences);
    expect(find.text('FixPK could not start'), findsOneWidget);
    preferences.failReads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to FixPK'), findsOneWidget);
  });

  testWidgets('failed completion write retains the introduction for retry', (
    tester,
  ) async {
    final preferences = MemoryPreferences()..failWrites = true;
    await _launch(tester, preferences);
    await _next(tester);
    await _next(tester);
    await _next(tester);
    expect(preferences.completed, isFalse);
    expect(find.text('Get started'), findsOneWidget);
    expect(
      find.text('We couldn’t save your progress. Please try again.'),
      findsOneWidget,
    );
    preferences.failWrites = false;
    await _next(tester);
    expect(find.text('Join FixPK'), findsOneWidget);
    expect(preferences.completed, isTrue);
  });

  testWidgets('existing users can go straight to sign in', (tester) async {
    final preferences = MemoryPreferences();
    await _launch(tester, preferences);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(preferences.completed, isTrue);
  });

  testWidgets(
    'an explicit recovery route remains reachable before onboarding',
    (tester) async {
      final router = createRouter(initialLocation: '/reset-password');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: MaterialApp.router(
            theme: FixPkTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Open your password reset link'), findsOneWidget);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets('all introduction actions fit a small phone at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _launch(tester, MemoryPreferences());
      for (var page = 0; page < 3; page++) {
        expect(
          find.byKey(const ValueKey('onboarding-next')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await _next(tester);
      }
      expect(find.text('Join FixPK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
