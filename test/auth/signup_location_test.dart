import 'dart:async';
import 'dart:convert';

import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/config/app_config.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:fixpk/features/auth/data/auth_repository.dart';
import 'package:fixpk/features/auth/presentation/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/memory_preferences.dart';

class SignupAuth implements AuthRepository {
  final calls = <Map<String, String>>[];
  AuthResponse response = AuthResponse();
  Completer<void>? pending;

  @override
  Future<AuthResponse> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String country,
    required String city,
  }) async {
    calls.add({'country': country, 'city': city});
    await pending?.future;
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _form(
  WidgetTester tester,
  SignupAuth auth,
  MemoryPreferences preferences,
) async {
  final router = GoRouter(
    initialLocation: '/sign-up',
    routes: [
      GoRoute(
        path: '/sign-up',
        builder: (_, _) => const AuthPage(createAccount: true),
      ),
      GoRoute(path: '/sign-in', builder: (_, _) => const AuthPage()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('Home opened')),
      ),
    ],
  );
  addTearDown(router.dispose);
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
        preferencesProvider.overrideWithValue(preferences),
        authRepositoryProvider.overrideWithValue(auth),
        authUserProvider.overrideWith((ref) => Stream.value(null)),
      ],
      child: MaterialApp.router(theme: FixPkTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  for (final entry in {
    'auth-name': 'Test customer',
    'auth-phone': '+923001234567',
    'auth-email': 'customer@example.test',
    'auth-password': 'test-password-123',
  }.entries) {
    await tester.enterText(find.byKey(ValueKey(entry.key)), entry.value);
  }
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.widgetWithText(FilledButton, 'Create account');
  await tester.scrollUntilVisible(
    button,
    250,
    scrollable: find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .last,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pump();
}

void main() {
  testWidgets(
    'signup requires country/city and preserves confirmation behavior',
    (tester) async {
      final auth = SignupAuth();
      final preferences = MemoryPreferences();
      await _form(tester, auth, preferences);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('account-country')),
            )
            .controller!
            .text,
        'Pakistan',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-country')),
        ' ',
      );
      await _submit(tester);
      expect(find.text('Enter your country.'), findsOneWidget);
      expect(find.text('Enter your city.'), findsOneWidget);
      expect(auth.calls, isEmpty);
      await tester.enterText(
        find.byKey(const ValueKey('account-country')),
        'Pakistan',
      );
      await tester.enterText(
        find.byKey(const ValueKey('account-city')),
        'Rawalpindi',
      );
      await _submit(tester);
      await tester.pumpAndSettle();
      expect(auth.calls, [
        {'country': 'Pakistan', 'city': 'Rawalpindi'},
      ]);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(
        find.text('Check your email to confirm your FixPK account.'),
        findsOneWidget,
      );
      expect(preferences.completed, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('a confirmed signup opens Home and blocks duplicate submits', (
    tester,
  ) async {
    final auth = SignupAuth()..pending = Completer<void>();
    auth.response = AuthResponse(
      session: Session(
        accessToken: 'test-access',
        refreshToken: 'test-refresh',
        tokenType: 'bearer',
        user: User(
          id: 'customer',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-10-13T00:00:00Z',
        ),
      ),
    );
    final preferences = MemoryPreferences();
    await _form(tester, auth, preferences);
    await tester.enterText(
      find.byKey(const ValueKey('account-city')),
      'Islamabad',
    );
    await _submit(tester);
    expect(auth.calls, hasLength(1));
    final busy = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(busy.onPressed, isNull);
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Home opened'), findsOneWidget);
    expect(preferences.completed, isTrue);
    expect(auth.calls, hasLength(1));
  });

  test(
    'country and city reach Supabase Auth and survive its response',
    () async {
      Map<String, dynamic>? body;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'sb_publishable_test',
        authOptions: const AuthClientOptions(
          autoRefreshToken: false,
          authFlowType: AuthFlowType.implicit,
        ),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/auth/v1/signup');
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'id': 'customer',
              'aud': 'authenticated',
              'created_at': '2026-10-13T00:00:00Z',
              'email': body!['email'],
              'user_metadata': body!['data'],
              'app_metadata': <String, dynamic>{},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final response = await AuthRepository(client).signUp(
        name: ' Customer ',
        phone: ' +923001234567 ',
        email: ' customer@example.test ',
        password: 'test-password-123',
        country: ' Pakistan ',
        city: ' Rawalpindi ',
      );
      expect(body!['data'], {
        'full_name': 'Customer',
        'phone': '+923001234567',
        'country': 'Pakistan',
        'city': 'Rawalpindi',
      });
      expect(response.user!.userMetadata!['city'], 'Rawalpindi');
      expect(response.session, isNull);
    },
  );
}
