import 'dart:async';
import 'dart:typed_data';

import 'package:fixpk/core/storage/device_store.dart';
import 'package:fixpk/core/storage/app_storage.dart';
import 'package:fixpk/app/providers.dart';
import 'package:fixpk/app/fixpk_app.dart';
import 'package:fixpk/features/requests/data/request_outbox.dart';
import 'package:fixpk/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native first launch remembers the introduction after restart', (
    tester,
  ) async {
    final preferences = LocalPreferencesStore(SharedPreferencesAsync());
    await preferences.setOnboardingCompleted(completed: false);
    final errorHandler = FlutterError.onError;
    app.main();
    FlutterError.onError = errorHandler;
    await tester.pumpAndSettle();
    expect(find.text('Welcome to FixPK'), findsOneWidget);
    for (var page = 0; page < 3; page++) {
      await tester.tap(find.byKey(const ValueKey('onboarding-next')));
      await tester.pumpAndSettle();
    }
    expect(find.text('Join FixPK'), findsOneWidget);
    expect(await preferences.getOnboardingCompleted(), isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    app.main();
    FlutterError.onError = errorHandler;
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('installed Home and all main tabs remain navigable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [startupRouteProvider.overrideWith((ref) async => '/home')],
        child: const FixPkApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Powering better\nliving, every day.'), findsOneWidget);
    for (final index in [1, 2, 3, 4, 0]) {
      await tester.tap(find.byType(NavigationDestination).at(index));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'native storage preserves offline attachments and reconnect sends once',
    (tester) async {
      final owner = 'integration-${const Uuid().v4()}';
      final file = OutboxFile(
        id: const Uuid().v4(),
        name: 'test.png',
        contentType: 'image/png',
        size: 4,
      );
      final request = QueuedRequest(
        id: const Uuid().v4(),
        ownerId: owner,
        serviceId: 'test-service',
        serviceName: 'Test service',
        addressId: 'test-address',
        notes: 'Local integration fixture',
        answers: const {},
        createdAt: DateTime.now().toUtc(),
        files: [file],
      );
      var online = false;
      var deliveries = 0;
      Future<void> send(
        QueuedRequest row,
        Future<Uint8List> Function(OutboxFile) read,
      ) async {
        if (!online) throw TimeoutException('Simulated disconnected transport');
        expect(await read(row.files.single), [1, 2, 3, 4]);
        deliveries++;
      }

      final first = RequestOutbox(
        store: DeviceStore(),
        currentUserId: () => owner,
        send: send,
      );
      await first.enqueue(request, {
        file.id: Uint8List.fromList([1, 2, 3, 4]),
      });
      await first.sync(force: true);
      expect((await first.list(owner)).single.problem, 'connection');
      first.dispose();
      // A fresh native store must find the data using path_provider on this OS.
      final restored = RequestOutbox(
        store: DeviceStore(),
        currentUserId: () => owner,
        send: send,
      );
      expect((await restored.list(owner)).single.id, request.id);
      online = true;
      await Future.wait([
        restored.sync(force: true),
        restored.sync(force: true),
      ]);
      expect(deliveries, 1);
      expect(await restored.list(owner), isEmpty);
      await restored.store.delete('outbox.$owner.index');
      restored.dispose();
    },
  );
}
