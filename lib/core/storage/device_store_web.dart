import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'durable_store.dart';

/// Web storage can be cleared by the browser; native installs use atomic files.
class DeviceStore implements DurableStore {
  final _storage = const FlutterSecureStorage();
  String _key(String key) => 'fixpk.offline.v1.$key';
  @override
  Future<Uint8List?> read(String key) async {
    final value = await _storage.read(key: _key(key));
    return value == null ? null : base64Decode(value);
  }

  @override
  Future<void> write(String key, Uint8List bytes) =>
      _storage.write(key: _key(key), value: base64Encode(bytes));
  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));
}
