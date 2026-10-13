import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/features/auth/data/auth_repository.dart';
import 'package:fixpk/features/auth/presentation/reset_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecordingAuth implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final passwords = <String>[];
  @override
  Future<void> updatePassword(String password) async => passwords.add(password);
}

void main() {
  testWidgets('a reset route without a session offers a new link', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/reset-password');
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authUserProvider.overrideWith((ref) => Stream.value(null))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open your password reset link'), findsOneWidget);
    await tester.tap(find.text('Go to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('recovery form validates confirmation and submits only once', (
    tester,
  ) async {
    final auth = RecordingAuth();
    final user = User(
      id: 'alice',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-10-12T00:00:00Z',
    );
    final router = GoRouter(
      initialLocation: '/reset-password',
      routes: [
        GoRoute(
          path: '/reset-password',
          builder: (_, _) => const ResetPasswordPage(),
        ),
        GoRoute(
          path: '/account',
          builder: (_, _) => const Scaffold(body: Text('Account updated')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith((ref) => Stream.value(user)),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'long-test-password',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'different');
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(auth.passwords, isEmpty);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'long-test-password',
    );
    await tester.tap(find.text('Update password'));
    await tester.pumpAndSettle();
    expect(auth.passwords, ['long-test-password']);
    expect(find.text('Account updated'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
