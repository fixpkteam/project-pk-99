import 'dart:async';

import 'durable_store.dart';

/// Cached data is displayed immediately; a refresh never hides usable content.
/// Do not use this for authorization, staff permissions or financial decisions.
class ReadCache {
  ReadCache(this.store);
  final DurableStore store;

  Stream<T> watch<T>(
    String key,
    Future<dynamic> Function() fetch,
    T Function(dynamic) decode,
  ) async* {
    var emitted = false;
    try {
      final cached = await store.readJson('cache.$key');
      if (cached != null) {
        yield decode(cached);
        emitted = true;
      }
    } on Object {
      // A missing/corrupt cache must never block a fresh server response.
    }
    try {
      final fresh = await fetch().timeout(const Duration(seconds: 15));
      final value = decode(fresh);
      try {
        await store.writeJson('cache.$key', fresh);
      } on Object {
        // Cache storage is best effort. Critical outbox writes are not.
      }
      yield value;
    } on Object {
      if (!emitted) rethrow;
    }
  }
}
