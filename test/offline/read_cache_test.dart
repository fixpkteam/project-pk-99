import 'dart:async';

import 'package:fixpk/core/storage/durable_store.dart';
import 'package:fixpk/core/storage/read_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import 'request_outbox_test.dart' show MemoryStore;

void main() {
  test('cached content is emitted before a slow network completes', () async {
    final store = MemoryStore();
    await store.writeJson('cache.catalogue', ['saved']);
    final network = Completer<List<String>>();
    final results = <List<String>>[];
    final sub = ReadCache(store)
        .watch(
          'catalogue',
          () => network.future,
          (data) => (data as List).cast<String>(),
        )
        .listen(results.add);
    await Future<void>.delayed(Duration.zero);
    expect(results, [
      ['saved'],
    ]);
    network.complete(['fresh']);
    await sub.asFuture<void>();
    expect(results, [
      ['saved'],
      ['fresh'],
    ]);
    expect(await store.readJson('cache.catalogue'), ['fresh']);
  });

  test('offline restart keeps cached catalogue visible', () async {
    final store = MemoryStore();
    await store.writeJson('cache.catalogue', ['saved']);
    final result = await ReadCache(store)
        .watch(
          'catalogue',
          () async => throw TimeoutException('offline'),
          (data) => data,
        )
        .toList();
    expect(result, [
      ['saved'],
    ]);
  });

  test(
    'no cached data produces a recoverable failure, not fake empty success',
    () async {
      await expectLater(
        ReadCache(MemoryStore())
            .watch(
              'new',
              () async => throw TimeoutException('offline'),
              (data) => data,
            )
            .toList(),
        throwsA(isA<TimeoutException>()),
      );
    },
  );

  test('private cached addresses are isolated by account key', () async {
    final store = MemoryStore();
    await store.writeJson('cache.user.alice.addresses', ['private address']);
    final bob = await ReadCache(store)
        .watch('user.bob.addresses', () async => <String>[], (data) => data)
        .toList();
    expect(bob, [<String>[]]);
  });
}
