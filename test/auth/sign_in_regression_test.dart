import 'dart:convert';

import 'package:fixpk/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'confirmed sign-in succeeds even when profiles INSERT is forbidden',
    () async {
      final calls = <http.Request>[];
      final client = SupabaseClient(
        'https://example.supabase.co',
        'public-test-key',
        httpClient: MockClient((request) async {
          calls.add(request);
          if (request.url.path == '/auth/v1/token') {
            return http.Response(
              jsonEncode({
                'access_token': 'test-session-token',
                'refresh_token': 'test-refresh-token',
                'token_type': 'bearer',
                'expires_in': 3600,
                'user': {
                  'id': 'customer-1',
                  'aud': 'authenticated',
                  'email': 'customer@example.test',
                  'created_at': '2026-10-14T00:00:00Z',
                  'email_confirmed_at': '2026-10-14T00:00:00Z',
                  'app_metadata': <String, dynamic>{},
                  'user_metadata': {'full_name': 'Customer'},
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response(
            '{"code":"42501","message":"profile insert forbidden"}',
            403,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await AuthRepository(client)
          .signIn(email: ' customer@example.test ', password: 'test-password');
      expect(client.auth.currentUser?.id, 'customer-1');
      expect(
        calls.length,
        1,
        reason: 'Login must not depend on a post-login profile write.',
      );
      expect(jsonDecode(calls.single.body)['email'], 'customer@example.test');
    },
  );
}
