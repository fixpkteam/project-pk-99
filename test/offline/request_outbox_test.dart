import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fixpk/core/storage/device_store_io.dart';
import 'package:fixpk/core/storage/durable_store.dart';
import 'package:fixpk/features/requests/data/request_outbox.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemoryStore implements DurableStore {
  final data = <String, Uint8List>{};
  bool fail = false;
  @override
  Future<Uint8List?> read(String key) async => data[key];
  @override
  Future<void> write(String key, Uint8List bytes) async {
    if (fail) throw StateError('Disk full');
    data[key] = bytes;
  }

  @override
  Future<void> delete(String key) async => data.remove(key);
}

QueuedRequest request({
  String id = 'r1',
  String owner = 'alice',
  bool file = false,
}) => QueuedRequest(
  id: id,
  ownerId: owner,
  serviceId: 'solar',
  serviceName: 'Solar quote',
  addressId: 'home',
  notes: 'Install panels',
  answers: {'q1': false},
  createdAt: DateTime.utc(2026, 10, 12),
  files: file
      ? [
          const OutboxFile(
            id: 'f1',
            name: 'roof.jpg',
            contentType: 'image/jpeg',
            size: 3,
          ),
        ]
      : [],
);

void main() {
  late MemoryStore store;
  String? owner;
  late DateTime now;
  setUp(() {
    store = MemoryStore();
    owner = 'alice';
    now = DateTime.utc(2026, 10, 12);
  });
  RequestOutbox box(RequestSender send, {DurableStore? storage}) {
    final outbox = RequestOutbox(
      store: storage ?? store,
      currentUserId: () => owner,
      send: send,
      clock: () => now,
    );
    addTearDown(outbox.dispose);
    return outbox;
  }

  test(
    'offline save acknowledges durable data without making a network call',
    () async {
      var sends = 0;
      final outbox = box((_, _) async {
        sends++;
      });
      await outbox.enqueue(request(), {});
      expect((await outbox.list('alice')).single.answers['q1'], false);
      expect(sends, 0);
    },
  );

  test(
    'native files and queue survive a new store and outbox instance',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'fixpk-outbox-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final first = box(
        (_, _) async {},
        storage: DeviceStore(directory: () async => directory),
      );
      await first.enqueue(request(file: true), {
        'f1': Uint8List.fromList([1, 2, 3]),
      });
      var delivered = false;
      final reopened = box((row, read) async {
        expect(row.id, 'r1');
        expect(await read(row.files.single), [1, 2, 3]);
        delivered = true;
      }, storage: DeviceStore(directory: () async => directory));
      expect(await reopened.list('alice'), hasLength(1));
      await reopened.sync();
      expect(delivered, true);
      expect(await reopened.list('alice'), isEmpty);
    },
  );

  test(
    'concurrent enqueues and double taps preserve one copy per UUID',
    () async {
      final outbox = box((_, _) async {});
      await Future.wait([
        outbox.enqueue(request(), {}),
        outbox.enqueue(request(), {}),
        outbox.enqueue(request(id: 'r2'), {}),
      ]);
      expect(await outbox.list('alice'), hasLength(2));
    },
  );

  test(
    'connection loss retains request; reconnect retries the same UUID',
    () async {
      final ids = <String>[];
      var online = false;
      final outbox = box((row, _) async {
        ids.add(row.id);
        if (!online) throw TimeoutException('response lost');
      });
      await outbox.enqueue(request(), {});
      await outbox.sync();
      expect((await outbox.list('alice')).single.problem, 'connection');
      await outbox.sync(); // Backoff prevents hammering an offline connection.
      expect(ids, ['r1']);
      online = true;
      now = now.add(const Duration(seconds: 16));
      await outbox.sync();
      expect(ids, ['r1', 'r1']);
      expect(await outbox.list('alice'), isEmpty);
    },
  );

  test('simultaneous sync triggers share one delivery', () async {
    var sends = 0;
    final gate = Completer<void>();
    final outbox = box((_, _) async {
      sends++;
      await gate.future;
    });
    await outbox.enqueue(request(), {});
    final syncs = [outbox.sync(), outbox.sync(force: true), outbox.sync()];
    await Future<void>.delayed(Duration.zero);
    gate.complete();
    await Future.wait(syncs);
    expect(sends, 1);
  });

  test(
    'signing out or switching account never sends the previous queue',
    () async {
      var sends = 0;
      final outbox = box((_, _) async {
        sends++;
      });
      await outbox.enqueue(request(), {});
      owner = 'bob';
      expect(await outbox.list('alice'), isEmpty);
      await outbox.sync();
      owner = null;
      await outbox.sync();
      expect(sends, 0);
      owner = 'alice';
      await outbox.sync();
      expect(sends, 1);
    },
  );

  test(
    'account change mid-flight retains original queue for idempotent recovery',
    () async {
      final outbox = box((_, _) async {
        owner = 'bob';
      });
      await outbox.enqueue(request(), {});
      await outbox.sync();
      owner = 'alice';
      expect(await outbox.list('alice'), hasLength(1));
    },
  );

  test('database rejection needs attention and does not block another valid request', () async {
    final outbox = box((row, _) async {
      if (row.id == 'r1') {
        throw const PostgrestException(message: 'invalid', code: '22023');
      }
    });
    await outbox.enqueue(request(), {});
    await outbox.enqueue(request(id: 'r2'), {});
    await outbox.sync();
    final remaining = await outbox.list('alice');
    expect(remaining, hasLength(1));
    expect(remaining.single.needsAttention, true);
  });

  test('attachment corruption is visible and never marked delivered', () async {
    final row = request(file: true);
    final outbox = box((r, read) async {
      await read(r.files.single);
    });
    await outbox.enqueue(row, {
      'f1': Uint8List.fromList([1, 2, 3]),
    });
    await store.delete(row.fileKey(row.files.single));
    await outbox.sync();
    expect((await outbox.list('alice')).single.problem, 'missing_file');
  });

  test(
    'disk failure never reports a saved request or discards an older one',
    () async {
      final outbox = box((_, _) async {});
      await outbox.enqueue(request(), {});
      store.fail = true;
      await expectLater(
        outbox.enqueue(request(id: 'r2'), {}),
        throwsStateError,
      );
      expect((await outbox.list('alice')).single.id, 'r1');
    },
  );

  test('corrupt queue is surfaced instead of silently overwritten', () async {
    store.data['outbox.alice.index'] = Uint8List.fromList([0, 1, 2]);
    final outbox = box((_, _) async {});
    await expectLater(
      outbox.enqueue(request(), {}),
      throwsA(isA<FormatException>()),
    );
    expect(store.data['outbox.alice.index'], [0, 1, 2]);
  });

  test('queue limits prevent unbounded memory and disk growth', () async {
    final outbox = box((_, _) async {});
    for (var i = 0; i < 20; i++) {
      await outbox.enqueue(request(id: '$i'), {});
    }
    await expectLater(
      outbox.enqueue(request(id: 'overflow'), {}),
      throwsStateError,
    );
    expect(await outbox.list('alice'), hasLength(20));
  });

  test(
    'local removal removes attachments but does not claim server cancellation',
    () async {
      final row = request(file: true);
      final outbox = box((_, _) async {});
      await outbox.enqueue(row, {
        'f1': Uint8List.fromList([1, 2, 3]),
      });
      await outbox.removeLocal('alice', row.id);
      expect(await outbox.list('alice'), isEmpty);
      expect(await store.read(row.fileKey(row.files.single)), isNull);
    },
  );

  test('only retry transient backend failures automatically', () {
    expect(
      requiresSignIn(
        const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
      ),
      true,
    );
    expect(
      requiresSignIn(
        const PostgrestException(message: 'denied', code: '42501'),
      ),
      false,
    );
    expect(
      isTransientFailure(
        const PostgrestException(message: 'busy', code: '503'),
      ),
      true,
    );
    expect(
      isTransientFailure(
        const PostgrestException(message: 'denied', code: '42501'),
      ),
      false,
    );
    expect(
      isTransientFailure(
        const PostgrestException(message: 'missing', code: 'PGRST202'),
      ),
      false,
    );
  });
}
