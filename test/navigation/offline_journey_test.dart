import 'dart:async';

import 'package:fixpk/app/app_router.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/core/config/app_config.dart';
import 'package:fixpk/core/theme/app_theme.dart';
import 'package:fixpk/features/catalogue/data/catalogue_repository.dart';
import 'package:fixpk/features/requests/data/outbox_providers.dart';
import 'package:fixpk/features/requests/data/request_outbox.dart';
import 'package:fixpk/features/requests/data/request_repository.dart';
import 'package:fixpk/features/services/data/services_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../offline/request_outbox_test.dart' show MemoryStore;

final _user = User(
  id: 'alice',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-10-12T00:00:00Z',
);
const _config = AppConfig(
  environment: AppEnvironment.staging,
  preview: false,
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'sb_publishable_test',
);
final _service = ServiceItem.fromRow({
  'id': 'solar',
  'category_id': 'energy',
  'name': 'Solar quote',
});
final _address = CustomerAddress.fromRow({
  'id': 'home',
  'label': 'Home',
  'address_line': 'Test street',
  'city': 'Islamabad',
});

void main() {
  testWidgets(
    'complete request form offline, see saved status, then send on reconnect',
    (tester) async {
      var online = false;
      var delivered = 0;
      final outbox = RequestOutbox(
        store: MemoryStore(),
        currentUserId: () => _user.id,
        send: (_, _) async {
          if (!online) throw TimeoutException('offline');
          delivered++;
        },
      );
      addTearDown(outbox.dispose);
      final router = createRouter(
        initialLocation:
            '/requests/new?serviceId=solar&context=Product%20quote',
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            configProvider.overrideWithValue(_config),
            authUserProvider.overrideWith((ref) => Stream.value(_user)),
            serviceCatalogueProvider.overrideWith(
              (ref) => Stream.value(
                ServiceCatalogue(categories: [], services: [_service]),
              ),
            ),
            serviceQuestionsProvider.overrideWith(
              (ref, id) => Stream.value(<ServiceQuestion>[]),
            ),
            customerAddressesProvider.overrideWith(
              (ref, id) => Stream.value([_address]),
            ),
            requestOutboxProvider.overrideWithValue(outbox),
          ],
          child: MaterialApp.router(
            theme: FixPkTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Product quote'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        final next = find.byKey(ValueKey('request-continue-$i'));
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      final submit = find.byKey(const ValueKey('request-continue-4'));
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Saved quote requests'), findsOneWidget);
      expect(await outbox.list(_user.id), hasLength(1));
      expect(delivered, 0);
      expect(find.textContaining('Saved on device'), findsOneWidget);
      online = true;
      await tester.tap(find.widgetWithText(FilledButton, 'Send now'));
      await tester.pumpAndSettle();
      expect(delivered, 1);
      expect(find.text('No requests waiting to send'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product gallery with several images has bounded thumbnails', (
    tester,
  ) async {
    final router = createRouter(initialLocation: '/products/solar-kit');
    addTearDown(router.dispose);
    final product = ProductRecord.fromRow(
      {'id': 'solar-kit', 'name': 'Solar Kit', 'is_available': true},
      images: List.generate(
        3,
        (i) => ProductImageRecord(
          url: 'https://example.invalid/$i.png',
          altText: 'Panel $i',
          sortOrder: i,
        ),
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          configProvider.overrideWithValue(_config),
          productCatalogueProvider.overrideWith(
            (ref) => Stream.value(
              ProductCatalogue(categories: [], products: [product]),
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: FixPkTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solar Kit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('home fits width $width with text scale $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final router = createRouter();
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp.router(
              theme: FixPkTheme.light,
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -650));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
