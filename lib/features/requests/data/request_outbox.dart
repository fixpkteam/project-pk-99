import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/durable_store.dart';

const offlineRequestMessage =
    'Your quote request is saved on this device. We’ll send it to the FixPK team when you’re back online with the app open.';

class OutboxFile {
  const OutboxFile({
    required this.id,
    required this.name,
    required this.contentType,
    required this.size,
  });
  final String id, name, contentType;
  final int size;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contentType': contentType,
    'size': size,
  };
  factory OutboxFile.fromJson(Map<String, dynamic> row) => OutboxFile(
    id: row['id'] as String,
    name: row['name'] as String,
    contentType: row['contentType'] as String,
    size: row['size'] as int,
  );
}

class QueuedRequest {
  const QueuedRequest({
    required this.id,
    required this.ownerId,
    required this.serviceId,
    required this.serviceName,
    required this.addressId,
    required this.notes,
    required this.answers,
    required this.createdAt,
    this.preferredDate,
    this.preferredTime,
    this.files = const [],
    this.attempts = 0,
    this.nextAttemptAt,
    this.problem,
  });
  final String id, ownerId, serviceId, serviceName, addressId, notes;
  final Map<String, dynamic> answers;
  final DateTime createdAt;
  final String? preferredDate, preferredTime;
  final List<OutboxFile> files;
  final int attempts;
  final DateTime? nextAttemptAt;
  // Only stable customer-safe codes are stored, never exception payloads.
  final String? problem;
  String fileKey(OutboxFile file) => 'outbox.$ownerId.$id.${file.id}';
  bool get needsAttention => problem == 'rejected' || problem == 'missing_file';
  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'serviceId': serviceId,
    'serviceName': serviceName,
    'addressId': addressId,
    'notes': notes,
    'answers': answers,
    'createdAt': createdAt.toIso8601String(),
    'preferredDate': preferredDate,
    'preferredTime': preferredTime,
    'files': files.map((f) => f.toJson()).toList(),
    'attempts': attempts,
    'nextAttemptAt': nextAttemptAt?.toIso8601String(),
    'problem': problem,
  };
  factory QueuedRequest.fromJson(Map<String, dynamic> row) => QueuedRequest(
    id: row['id'] as String,
    ownerId: row['ownerId'] as String,
    serviceId: row['serviceId'] as String,
    serviceName: row['serviceName'] as String,
    addressId: row['addressId'] as String,
    notes: row['notes'] as String,
    answers: Map<String, dynamic>.from(row['answers'] as Map),
    createdAt: DateTime.parse(row['createdAt'] as String),
    preferredDate: row['preferredDate'] as String?,
    preferredTime: row['preferredTime'] as String?,
    files: (row['files'] as List)
        .map((f) => OutboxFile.fromJson(Map<String, dynamic>.from(f as Map)))
        .toList(),
    attempts: row['attempts'] as int? ?? 0,
    nextAttemptAt: DateTime.tryParse('${row['nextAttemptAt'] ?? ''}'),
    problem: row['problem'] as String?,
  );
  QueuedRequest failed(String problem, DateTime next) =>
      QueuedRequest.fromJson({
        ...toJson(),
        'problem': problem,
        'attempts': attempts + 1,
        'nextAttemptAt': next.toIso8601String(),
      });
}

typedef RequestSender = Future<void> Function(
  QueuedRequest request,
  Future<Uint8List> Function(OutboxFile) readFile,
);

class RequestOutbox {
  RequestOutbox({
    required this.store,
    required this.currentUserId,
    required this.send,
    this.onSent,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;
  final DurableStore store;
  final String? Function() currentUserId;
  final RequestSender send;
  final void Function(String ownerId)? onSent;
  final DateTime Function() clock;
  final _changes = StreamController<void>.broadcast();
  Future<void> _writes = Future.value();
  Future<void>? _syncing;
  bool _disposed = false;
  String _key(String owner) => 'outbox.$owner.index';

  Future<T> _serial<T>(Future<T> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<List<QueuedRequest>> list(String owner) async {
    if (currentUserId() != owner) return [];
    final raw = await store.readJson(_key(owner));
    // A corrupt index is an error, never silently replaced with an empty queue.
    return raw == null
        ? []
        : (raw as List)
              .map(
                (r) =>
                    QueuedRequest.fromJson(Map<String, dynamic>.from(r as Map)),
              )
              .where((r) => r.ownerId == owner)
              .toList();
  }

  Stream<List<QueuedRequest>> watch(String owner) => Stream.multi((controller) {
    Future<void> emit() async {
      try {
        controller.add(await list(owner));
      } on Object catch (error, stack) {
        controller.addError(error, stack);
      }
    }

    final sub = _changes.stream.listen((_) => unawaited(emit()));
    controller.onCancel = sub.cancel;
    unawaited(emit());
  });

  Future<void> _save(String owner, List<QueuedRequest> rows) async {
    await store.writeJson(_key(owner), rows.map((r) => r.toJson()).toList());
    if (!_disposed) _changes.add(null);
  }

  Future<void> enqueue(QueuedRequest request, Map<String, Uint8List> files) =>
      _serial(() async {
        if (currentUserId() != request.ownerId) {
          throw StateError('Sign in required');
        }
        final rows = await list(request.ownerId);
        if (rows.any((r) => r.id == request.id)) return;
        final size = request.files.fold<int>(0, (total, f) => total + f.size);
        final queuedSize = rows
            .expand((r) => r.files)
            .fold<int>(0, (total, f) => total + f.size);
        if (rows.length >= 20 ||
            request.files.length > 5 ||
            size > 20 * 1024 * 1024 ||
            queuedSize + size > 100 * 1024 * 1024) {
          throw StateError('Outbox capacity reached');
        }
        final written = <String>[];
        try {
          for (final file in request.files) {
            final bytes = files[file.id];
            if (bytes == null ||
                bytes.length != file.size ||
                file.size > 5 * 1024 * 1024) {
              throw StateError('Invalid attachment');
            }
            await store.write(request.fileKey(file), bytes);
            written.add(request.fileKey(file));
          }
          if (currentUserId() != request.ownerId) {
            throw StateError('Account changed');
          }
          await _save(request.ownerId, [...rows, request]);
        } on Object {
          for (final key in written) {
            try {
              await store.delete(key);
            } on Object {
              /* Retry cleanup later. */
            }
          }
          rethrow;
        }
      });

  Future<void> sync({bool force = false}) {
    if (_disposed) return Future.value();
    return _syncing ??= _drain(force).whenComplete(() => _syncing = null);
  }

  Future<void> _drain(bool force) async {
    final owner = currentUserId();
    if (owner == null) return;
    final rows = await list(owner);
    for (final request in rows) {
      if (_disposed || currentUserId() != owner) return;
      if (!force &&
          (request.needsAttention ||
              (request.nextAttemptAt?.isAfter(clock()) ?? false))) {
        continue;
      }
      try {
        await send(request, (file) async {
          if (currentUserId() != owner) {
            throw const AuthException('Account changed');
          }
          final bytes = await store.read(request.fileKey(file));
          if (bytes == null || bytes.length != file.size) {
            throw const MissingOutboxFile();
          }
          return bytes;
        });
        // Never remove another account's queue after a mid-flight account change.
        if (currentUserId() != owner) return;
        await _serial(() async {
          final latest = await list(owner);
          await _save(owner, latest.where((r) => r.id != request.id).toList());
        });
        for (final file in request.files) {
          try {
            await store.delete(request.fileKey(file));
          } on Object {
            /* Best effort after confirmed delivery. */
          }
        }
        onSent?.call(owner);
      } on Object catch (error) {
        if (_disposed || currentUserId() != owner) return;
        final problem = error is MissingOutboxFile
            ? 'missing_file'
            : requiresSignIn(error)
            ? 'sign_in'
            : isTransientFailure(error)
            ? 'connection'
            : 'rejected';
        final seconds = min(300, 15 * (1 << min(request.attempts, 5)));
        await _serial(() async {
          final latest = await list(owner);
          await _save(
            owner,
            latest
                .map(
                  (r) => r.id == request.id
                      ? r.failed(
                          problem,
                          clock().add(Duration(seconds: seconds)),
                        )
                      : r,
                )
                .toList(),
          );
        });
        if (problem == 'connection' || problem == 'sign_in') return;
      }
    }
  }

  /// Local removal only; a timed-out request may already exist on the server.
  Future<void> removeLocal(String owner, String id) async {
    await _syncing;
    await _serial(() async {
      if (currentUserId() != owner) throw StateError('Account changed');
      final rows = await list(owner);
      final removed = rows.where((r) => r.id == id).toList();
      await _save(owner, rows.where((r) => r.id != id).toList());
      for (final row in removed) {
        for (final file in row.files) {
          await store.delete(row.fileKey(file));
        }
      }
    });
  }

  void dispose() {
    _disposed = true;
    unawaited(_changes.close());
  }
}

class MissingOutboxFile implements Exception {
  const MissingOutboxFile();
}

bool requiresSignIn(Object error) =>
    (error is AuthException && !isTransientFailure(error)) ||
    (error is PostgrestException &&
        const {
          '401',
          'PGRST301',
          'PGRST302',
          'PGRST303',
        }.contains(error.code)) ||
    (error is StorageException && error.statusCode == '401');

bool isTransientFailure(Object error) {
  if (error is TimeoutException ||
      error is http.ClientException ||
      error is AuthRetryableFetchException) {
    return true;
  }
  if (error is PostgrestException) {
    final code = error.code ?? '';
    return code.startsWith('08') ||
        code == '429' ||
        code.startsWith('5') ||
        code == 'PGRST000' ||
        code == 'PGRST001' ||
        code == 'PGRST002' ||
        code == 'PGRST003';
  }
  if (error is StorageException) {
    final status = int.tryParse(error.statusCode ?? '');
    return status == 429 || (status != null && status >= 500);
  }
  return false;
}
