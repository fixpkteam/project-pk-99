import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:fixpk/features/care/data/care_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets(
    'admin opens a customer quote and reads requirements and address',
    (tester) async {
      final router = createRouter(initialLocation: '/staff/requests');
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authUserProvider.overrideWith(
              (ref) => Stream.value(
                User(
                  id: 'admin',
                  appMetadata: {},
                  userMetadata: {},
                  aud: 'authenticated',
                  createdAt: '2026-10-14',
                ),
              ),
            ),
            staffRoleListProvider.overrideWith(
              (ref, id) async => [StaffRoleRecord(userId: id, role: 'admin')],
            ),
            staffRequestPageProvider.overrideWith(
              (ref, page) async => [
                const StaffRequestSummary(
                  id: 'request-1',
                  reference: 'FPK-0001',
                  serviceId: 'web',
                  status: 'submitted',
                  createdAt: null,
                  serviceName: 'Website Design & Development',
                  customerName: 'Test Customer',
                ),
              ],
            ),
            staffRequestDetailProvider.overrideWith(
              (ref, id) async => {
                'id': id,
                'public_reference': 'FPK-0001',
                'status': 'submitted',
                'services': {'name': 'Website Design & Development'},
                'profiles': {
                  'full_name': 'Test Customer',
                  'phone': '+923001234567',
                },
                'addresses': {
                  'address_line': 'Customer office',
                  'city': 'Islamabad',
                },
                'service_request_answers': [
                  {
                    'answer_value': 'A five-page business website',
                    'service_questions': {
                      'label': 'Describe your requirements',
                    },
                  },
                ],
                'request_attachments': <Map<String, dynamic>>[],
              },
            ),
          ],
          child: MaterialApp.router(
            theme: FixPkTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Website Design & Development'), findsOneWidget);
      await tester.tap(find.text('Website Design & Development'));
      await tester.pumpAndSettle();
      expect(find.text('Request details'), findsOneWidget);
      expect(find.text('Customer office, Islamabad'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('A five-page business website'),
        250,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('A five-page business website'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('customer cannot open the staff request queue', (tester) async {
    final router = createRouter(initialLocation: '/staff/requests');
    addTearDown(router.dispose);
    var fetched = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserProvider.overrideWith(
            (ref) => Stream.value(
              User(
                id: 'customer',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2026-10-14',
              ),
            ),
          ),
          staffRoleListProvider.overrideWith((ref, id) async => []),
          staffRequestPageProvider.overrideWith((ref, page) async {
            fetched = true;
            return [];
          }),
        ],
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Staff access required'), findsOneWidget);
    expect(fetched, isFalse);
    expect(tester.takeException(), isNull);
  });
}
